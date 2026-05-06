<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Throwable;

class ProjectAiChatController extends Controller
{
    public function __invoke(Request $request, string $project): JsonResponse
    {
        try {
            $validated = $request->validate([
                'message' => ['required', 'string', 'max:2000'],
                'messages' => ['array', 'max:10'],
                'messages.*.role' => ['required_with:messages', 'in:user,assistant'],
                'messages.*.content' => ['required_with:messages', 'string', 'max:2000'],
            ]);

            $token = $this->ensureSupabaseSession($request);
            $projectContext = $this->loadProjectContext($token, $project);

            $apiKey = config('services.groq.key');

            if (! $apiKey) {
                return response()->json([
                    'message' => 'Falta configurar GROQ_API_KEY en Vercel.',
                ], 500);
            }

            $history = collect($validated['messages'] ?? [])
                ->take(-8)
                ->map(fn ($message) => [
                    'role' => $message['role'],
                    'content' => $message['content'],
                ])
                ->values()
                ->all();
            $context = $this->compactContext($projectContext);

            $messages = [
                [
                    'role' => 'system',
                    'content' => implode(' ', [
                        'Eres Blueprint AI, un copiloto profesional para gestion de proyectos de software.',
                        'En caso de recibir un prompt no dirigido al area de software, responde brevemente explicando tu proposito.',
                        'Responde en espanol claro y accionable.',
                        'Ayuda con backlog, riesgos, criterios de aceptacion, planeacion y seguimiento.',
                        'Usa el contexto del proyecto como fuente principal. No inventes datos especificos que no esten en el contexto o en el mensaje del usuario.',
                        'Antes de proponer tareas nuevas revisa las tareas existentes del contexto y evita duplicados por titulo, descripcion o intencion.',
                        'Si el usuario pide resumen, riesgos o criterios de aceptacion, usa las tareas existentes, estados, prioridades, fechas, estimaciones y miembros del contexto.',
                        'Cuando el usuario pida generar tareas, backlog, subtareas o plan de trabajo, responde solo con JSON valido, sin markdown, sin texto antes ni despues.',
                        'El JSON para tareas debe tener exactamente esta estructura: {"tasks":[{"title":"string","description":"string","priority":"low|medium|high","estimated_hours":number,"story_points":number|null,"due_date":"YYYY-MM-DD|null","status_id":1}]}',
                        'Cada tarea debe cuadrar con la tabla tasks: title requerido, description puede ser texto breve, priority solo low medium o high, estimated_hours numero mayor o igual a 0, story_points numero entero mayor o igual a 0 o null, due_date fecha YYYY-MM-DD o null, status_id siempre 1 para tareas nuevas.',
                        'Genera entre 6 y 10 tareas bien agrupadas y evita listas excesivamente largas.',
                        'No uses fechas pasadas. Si el usuario no da fechas futuras concretas, usa due_date null.',
                        'No incluyas id, project_id, created_by, created_at, updated_at, task_status ni task_assignments porque el sistema los agrega o relaciona automaticamente.',
                        'Si el usuario pide algo que no sea generar tareas, responde en texto normal y profesional.',
                        "Project ID: {$project}.",
                        'Contexto actual del proyecto en JSON compacto:',
                        $context,
                    ]),
                ],
                ...$history,
                [
                    'role' => 'user',
                    'content' => $validated['message'],
                ],
            ];

            $response = $this->httpClient()
                ->withToken($apiKey)
                ->acceptJson()
                ->post('https://api.groq.com/openai/v1/chat/completions', [
                    'model' => config('services.groq.model'),
                    'messages' => $messages,
                    'temperature' => 0.35,
                    'max_tokens' => 1800,
                ]);

            if ($response->failed()) {
                report_if($response->serverError(), new \RuntimeException($response->body()));

                return response()->json([
                    'message' => $response->json('error.message') ?: 'Groq no pudo responder en este momento. Intenta de nuevo en unos segundos.',
                ], $response->status());
            }

            return response()->json([
                'reply' => $response->json('choices.0.message.content') ?: 'No pude generar una respuesta util en este momento.',
            ]);
        } catch (ConnectionException $exception) {
            report($exception);

            return response()->json([
                'message' => 'No se pudo conectar con Groq o Supabase desde el servidor. Intenta de nuevo en unos segundos.',
            ], 502);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'message' => app()->hasDebugModeEnabled()
                    ? $exception->getMessage()
                    : 'El copiloto tuvo un error interno. Revisa las variables GROQ_API_KEY, VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY en Vercel.',
            ], 500);
        }
    }

    private function ensureSupabaseSession(Request $request): string
    {
        $token = $request->bearerToken();

        abort_if(! $token || ! $this->supabaseUrl() || ! $this->supabaseAnonKey(), 401, 'Sesion no valida.');

        $response = $this->supabaseClient($token)->get($this->supabaseUrl().'/auth/v1/user');

        abort_if($response->failed(), 401, 'Sesion no valida.');

        return $token;
    }

    private function loadProjectContext(string $token, string $projectId): array
    {
        $memberResponse = $this->supabaseClient($token)->get($this->restUrl('project_members'), [
            'select' => 'project_role',
            'project_id' => "eq.{$projectId}",
            'limit' => 1,
        ]);

        abort_if($memberResponse->failed(), 403, 'No se pudo validar tu acceso al proyecto.');

        $member = $memberResponse->json('0');

        abort_if(! $member, 403, 'No tienes acceso a este proyecto.');
        abort_if(($member['project_role'] ?? null) !== 'manager', 403, 'Solo un manager del proyecto puede usar el copiloto.');

        $projectResponse = $this->supabaseClient($token)->get($this->restUrl('projects'), [
            'select' => 'id,name,description,status,start_date,end_date',
            'id' => "eq.{$projectId}",
            'limit' => 1,
        ]);

        abort_if($projectResponse->failed() || ! $projectResponse->json('0'), 404, 'Proyecto no encontrado.');

        $tasksResponse = $this->supabaseClient($token)->get($this->restUrl('tasks'), [
            'select' => 'title,description,status_id,priority,estimated_hours,story_points,due_date,task_status(label),task_assignments(profiles(name,email))',
            'project_id' => "eq.{$projectId}",
            'order' => 'created_at.desc',
            'limit' => 80,
        ]);

        abort_if($tasksResponse->failed(), 403, 'No se pudo cargar el contexto de tareas.');

        $membersResponse = $this->supabaseClient($token)->get($this->restUrl('project_members'), [
            'select' => 'project_role,profiles(name,email)',
            'project_id' => "eq.{$projectId}",
            'limit' => 30,
        ]);

        abort_if($membersResponse->failed(), 403, 'No se pudo cargar el contexto de miembros.');

        return [
            'project' => $projectResponse->json('0') ?? [],
            'tasks' => collect($tasksResponse->json() ?? [])
                ->map(function (array $task): array {
                    $assignment = $this->firstRelation($task['task_assignments'] ?? null);

                    return [
                        'title' => $task['title'] ?? null,
                        'description' => $task['description'] ?? null,
                        'status' => $this->statusLabel($task['task_status']['label'] ?? null, $task['status_id'] ?? null),
                        'status_id' => $task['status_id'] ?? null,
                        'priority' => $task['priority'] ?? null,
                        'estimated_hours' => $task['estimated_hours'] ?? null,
                        'story_points' => $task['story_points'] ?? null,
                        'due_date' => $task['due_date'] ?? null,
                        'assigned_to' => $assignment['profiles']['name'] ?? $assignment['profiles']['email'] ?? null,
                    ];
                })
                ->all(),
            'members' => collect($membersResponse->json() ?? [])
                ->map(fn (array $member): array => [
                    'name' => $member['profiles']['name'] ?? $member['profiles']['email'] ?? null,
                    'role' => $member['project_role'] ?? null,
                ])
                ->all(),
        ];
    }

    private function supabaseClient(string $token): PendingRequest
    {
        return $this->httpClient()
            ->acceptJson()
            ->withHeaders([
                'apikey' => $this->supabaseAnonKey(),
                'Authorization' => "Bearer {$token}",
            ]);
    }

    private function restUrl(string $table): string
    {
        return $this->supabaseUrl().'/rest/v1/'.$table;
    }

    private function supabaseUrl(): string
    {
        return rtrim((string) config('services.supabase.url'), '/');
    }

    private function supabaseAnonKey(): string
    {
        return (string) config('services.supabase.anon_key');
    }

    private function httpClient(): PendingRequest
    {
        $request = Http::timeout(30);

        if (! config('services.http.verify_ssl')) {
            $request = $request->withoutVerifying();
        }

        return $request;
    }

    private function firstRelation(mixed $relation): ?array
    {
        if (is_array($relation) && array_is_list($relation)) {
            return $relation[0] ?? null;
        }

        return is_array($relation) ? $relation : null;
    }

    private function statusLabel(?string $label, mixed $statusId): string
    {
        return $label ?: match ((int) $statusId) {
            1 => 'Pendiente',
            2 => 'En progreso',
            3 => 'Completada',
            default => 'Sin estado',
        };
    }

    private function compactContext(array $context): string
    {
        $project = $context['project'] ?? [];
        $tasks = collect($context['tasks'] ?? [])
            ->take(80)
            ->map(fn ($task) => [
                'title' => $this->shortText($task['title'] ?? '', 120),
                'description' => $this->shortText($task['description'] ?? '', 180),
                'status' => $task['status'] ?? null,
                'status_id' => $task['status_id'] ?? null,
                'priority' => $task['priority'] ?? null,
                'estimated_hours' => $task['estimated_hours'] ?? null,
                'story_points' => $task['story_points'] ?? null,
                'due_date' => $task['due_date'] ?? null,
                'assigned_to' => $this->shortText($task['assigned_to'] ?? '', 80),
            ])
            ->values()
            ->all();
        $members = collect($context['members'] ?? [])
            ->take(30)
            ->map(fn ($member) => [
                'name' => $this->shortText($member['name'] ?? '', 80),
                'role' => $member['role'] ?? null,
            ])
            ->values()
            ->all();

        return json_encode([
            'project' => [
                'name' => $this->shortText($project['name'] ?? '', 120),
                'description' => $this->shortText($project['description'] ?? '', 220),
                'status' => $project['status'] ?? null,
                'start_date' => $project['start_date'] ?? null,
                'end_date' => $project['end_date'] ?? null,
            ],
            'tasks' => $tasks,
            'members' => $members,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    private function shortText(mixed $value, int $limit): ?string
    {
        $text = trim((string) $value);

        if ($text === '') {
            return null;
        }

        return mb_strlen($text) > $limit ? mb_substr($text, 0, $limit) : $text;
    }
}
