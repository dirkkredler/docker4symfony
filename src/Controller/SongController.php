<?php

declare(strict_types=1); 

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

#[Route("/api/songs/{id<\d+>}", methods: ["GET"])]
final class SongController
{
    public function __invoke(int $id): JsonResponse
    {
        $songs = [
            $id => [
                'id' => $id,
                'name' => 'Waterfalls',
                'url' => 'https://symfonycasts.s3.amazonaws.com/sample.mp3',
            ],
        ];

        return new JsonResponse($songs[$id]);
    }
}
