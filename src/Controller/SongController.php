<?php

declare(strict_types=1); 

namespace App\Controller;

use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

#[Route("/api/songs/{id<\d+>}", methods: ["GET"])]
final class SongController
{
    public function __construct(private LoggerInterface $logger)
    {
    }

    public function __invoke(int $id): JsonResponse
    {
        $songs = [
            $id => [
                'id' => $id,
                'name' => 'Waterfalls',
                'url' => 'https://symfonycasts.s3.amazonaws.com/sample.mp3',
            ],
        ];

        $this->logger->info("Song id: {$id}");
        $this->logger->info("Song id: {id}", [
            'id' => $id
        ]);


        return new JsonResponse($songs[$id]);
    }
}
