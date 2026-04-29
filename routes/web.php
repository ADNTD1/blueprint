<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ProjectAiChatController;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

Route::get('/', function () {
    return Inertia::render('Landing', [
        'canLogin' => Route::has('login'),
        'canRegister' => Route::has('register'),
        'laravelVersion' => Application::VERSION,
        'phpVersion' => PHP_VERSION,
    ]);
});

Route::get('/pricing', function () {
    return Inertia::render('Pricing');
});

Route::get('/about', function () {
    return Inertia::render('About');
});

Route::get('/support', function () {
    return Inertia::render('Support');
});

Route::get('/verify-email', function (\Illuminate\Http\Request $request) {
    return Inertia::render('Auth/VerifyEmail', [
        'email' => $request->query('email') // Pasamos el email por query string si viene
    ]);
})->name('verification.notice');

Route::get('/dashboard', function () {
    return Inertia::render('Dashboard');
})->name('dashboard');

Route::get('/projects/{id}', function ($id) {
    return Inertia::render('Projects/Show', ['id' => $id]);
})->name('projects.show');

Route::post('/projects/{project}/ai-chat', ProjectAiChatController::class)
    ->middleware('throttle:20,1')
    ->whereUuid('project')
    ->name('projects.ai-chat');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';
