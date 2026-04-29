<?php

use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;

it('rejects ai chat requests without a Supabase bearer token', function () {
    $projectId = '11111111-1111-1111-1111-111111111111';

    $this->postJson(route('projects.ai-chat', $projectId), [
        'message' => 'Resume el proyecto.',
    ])->assertUnauthorized();
});

it('rejects ai chat requests from non manager project members', function () {
    $projectId = '11111111-1111-1111-1111-111111111111';

    config([
        'services.supabase.url' => 'https://example.supabase.co',
        'services.supabase.anon_key' => 'anon-key',
        'services.groq.key' => 'groq-key',
    ]);

    Http::fake(function (Request $request) {
        if (str_contains($request->url(), '/auth/v1/user')) {
            return Http::response(['id' => 'user-id']);
        }

        if (str_contains($request->url(), '/rest/v1/project_members')) {
            return Http::response([
                ['project_role' => 'developer'],
            ]);
        }

        return Http::response([], 500);
    });

    $this->withToken('valid-token')
        ->postJson(route('projects.ai-chat', $projectId), [
            'message' => 'Resume el proyecto.',
        ])
        ->assertForbidden()
        ->assertJsonPath('message', 'Solo un manager del proyecto puede usar el copiloto.');

    Http::assertNotSent(fn (Request $request) => str_contains($request->url(), 'api.groq.com'));
});

it('builds ai context on the server for manager project members', function () {
    $projectId = '11111111-1111-1111-1111-111111111111';

    config([
        'services.supabase.url' => 'https://example.supabase.co',
        'services.supabase.anon_key' => 'anon-key',
        'services.groq.key' => 'groq-key',
        'services.groq.model' => 'test-model',
    ]);

    Http::fake(function (Request $request) {
        $url = $request->url();

        if (str_contains($url, '/auth/v1/user')) {
            return Http::response(['id' => 'user-id']);
        }

        if (str_contains($url, '/rest/v1/project_members') && ! str_contains($url, 'profiles')) {
            return Http::response([
                ['project_role' => 'manager'],
            ]);
        }

        if (str_contains($url, '/rest/v1/projects')) {
            return Http::response([
                [
                    'id' => '11111111-1111-1111-1111-111111111111',
                    'name' => 'Proyecto Seguro',
                    'description' => 'Contexto desde servidor',
                    'status' => 'active',
                    'start_date' => null,
                    'end_date' => null,
                ],
            ]);
        }

        if (str_contains($url, '/rest/v1/tasks')) {
            return Http::response([
                [
                    'title' => 'Definir backlog',
                    'description' => 'Preparar tareas iniciales',
                    'status_id' => 1,
                    'priority' => 'high',
                    'estimated_hours' => 2,
                    'story_points' => 3,
                    'due_date' => null,
                    'task_status' => ['label' => 'Pendiente'],
                    'task_assignments' => [],
                ],
            ]);
        }

        if (str_contains($url, '/rest/v1/project_members') && str_contains($url, 'profiles')) {
            return Http::response([
                [
                    'project_role' => 'manager',
                    'profiles' => ['name' => 'Ada', 'email' => 'ada@example.test'],
                ],
            ]);
        }

        if (str_contains($url, 'api.groq.com')) {
            return Http::response([
                'choices' => [
                    ['message' => ['content' => 'El proyecto esta activo.']],
                ],
            ]);
        }

        return Http::response([], 500);
    });

    $this->withToken('valid-token')
        ->postJson(route('projects.ai-chat', $projectId), [
            'message' => 'Resume el proyecto.',
            'context' => ['project' => ['name' => 'Contexto manipulado']],
        ])
        ->assertOk()
        ->assertJsonPath('reply', 'El proyecto esta activo.');

    Http::assertSent(function (Request $request) {
        if (! str_contains($request->url(), 'api.groq.com')) {
            return false;
        }

        $messages = $request->data()['messages'] ?? [];
        $systemPrompt = $messages[0]['content'] ?? '';

        return str_contains($systemPrompt, 'Proyecto Seguro')
            && ! str_contains($systemPrompt, 'Contexto manipulado');
    });
});
