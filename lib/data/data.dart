final userJsonString = [
  {
    "userId": "user123",
    "username": "JohnDoe",
    "profileImageUrl": "https://placekitten.com/200/200",
    "totalPoints": 1250,
    "streak": 12,
    "wordsLearned": 245,
    "lessonsCompleted": 28,
    "lastUpdated": {"_seconds": 1712406000, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1709641200, "_nanoseconds": 0},
  },
  {
    "userId": "user456",
    "username": "JaneSmith",
    "profileImageUrl": "https://placekitten.com/201/201",
    "totalPoints": 1570,
    "streak": 21,
    "wordsLearned": 310,
    "lessonsCompleted": 35,
    "lastUpdated": {"_seconds": 1712419500, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1708345600, "_nanoseconds": 0},
  },
  {
    "userId": "user789",
    "username": "AlexWilson",
    "profileImageUrl": "https://placekitten.com/202/202",
    "totalPoints": 980,
    "streak": 8,
    "wordsLearned": 195,
    "lessonsCompleted": 22,
    "lastUpdated": {"_seconds": 1712352000, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1710072000, "_nanoseconds": 0},
  },
  {
    "userId": "user101",
    "username": "SamJohnson",
    "profileImageUrl": "https://placekitten.com/203/203",
    "totalPoints": 2100,
    "streak": 30,
    "wordsLearned": 410,
    "lessonsCompleted": 42,
    "lastUpdated": {"_seconds": 1712440800, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1707222000, "_nanoseconds": 0},
  },
  {
    "userId": "user202",
    "username": "TaylorBrown",
    "profileImageUrl": "https://placekitten.com/204/204",
    "totalPoints": 1340,
    "streak": 14,
    "wordsLearned": 268,
    "lessonsCompleted": 31,
    "lastUpdated": {"_seconds": 1712380800, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1709814000, "_nanoseconds": 0},
  },
  {
    "userId": "user303",
    "username": "PatLee",
    "profileImageUrl": "https://placekitten.com/205/205",
    "totalPoints": 725,
    "streak": 5,
    "wordsLearned": 145,
    "lessonsCompleted": 18,
    "lastUpdated": {"_seconds": 1712361600, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1710763200, "_nanoseconds": 0},
  },
  {
    "userId": "user404",
    "username": "JordanRoberts",
    "profileImageUrl": "https://placekitten.com/206/206",
    "totalPoints": 1680,
    "streak": 25,
    "wordsLearned": 336,
    "lessonsCompleted": 38,
    "lastUpdated": {"_seconds": 1712437200, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1707654000, "_nanoseconds": 0},
  },
  {
    "userId": "user505",
    "username": "CaseyMorgan",
    "profileImageUrl": "https://placekitten.com/207/207",
    "totalPoints": 890,
    "streak": 9,
    "wordsLearned": 178,
    "lessonsCompleted": 20,
    "lastUpdated": {"_seconds": 1712372400, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1710504000, "_nanoseconds": 0},
  },
  {
    "userId": "user606",
    "username": "RileyGarcia",
    "profileImageUrl": "https://placekitten.com/208/208",
    "totalPoints": 1190,
    "streak": 11,
    "wordsLearned": 238,
    "lessonsCompleted": 27,
    "lastUpdated": {"_seconds": 1712397600, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1709468400, "_nanoseconds": 0},
  },
  {
    "userId": "user707",
    "username": "QuinnWilliams",
    "profileImageUrl": "https://placekitten.com/209/209",
    "totalPoints": 1430,
    "streak": 16,
    "wordsLearned": 286,
    "lessonsCompleted": 33,
    "lastUpdated": {"_seconds": 1712412000, "_nanoseconds": 0},
    "createdAt": {"_seconds": 1708777200, "_nanoseconds": 0},
  },
];

final activitiesJsonString = {
  "user123": [
    {
      "activityType": "lesson",
      "pointsEarned": 50,
      "completedAt": {"_seconds": 1712406000, "_nanoseconds": 0},
    },
    {
      "activityType": "vocabulary",
      "pointsEarned": 25,
      "completedAt": {"_seconds": 1712319600, "_nanoseconds": 0},
    },
    {
      "activityType": "quiz",
      "pointsEarned": 75,
      "completedAt": {"_seconds": 1712233200, "_nanoseconds": 0},
    },
    {
      "activityType": "practice",
      "pointsEarned": 30,
      "completedAt": {"_seconds": 1712146800, "_nanoseconds": 0},
    },
  ],
  "user456": [
    {
      "activityType": "lesson",
      "pointsEarned": 50,
      "completedAt": {"_seconds": 1712419500, "_nanoseconds": 0},
    },
    {
      "activityType": "vocabulary",
      "pointsEarned": 40,
      "completedAt": {"_seconds": 1712333100, "_nanoseconds": 0},
    },
    {
      "activityType": "quiz",
      "pointsEarned": 80,
      "completedAt": {"_seconds": 1712246700, "_nanoseconds": 0},
    },
    {
      "activityType": "practice",
      "pointsEarned": 35,
      "completedAt": {"_seconds": 1712160300, "_nanoseconds": 0},
    },
  ],
};

final rankHistoryJsonString = {
  "user123": [
    {
      "date": {"_seconds": 1711756800, "_nanoseconds": 0},
      "rank": 4,
    },
    {
      "date": {"_seconds": 1711843200, "_nanoseconds": 0},
      "rank": 4,
    },
    {
      "date": {"_seconds": 1711929600, "_nanoseconds": 0},
      "rank": 3,
    },
    {
      "date": {"_seconds": 1712016000, "_nanoseconds": 0},
      "rank": 3,
    },
    {
      "date": {"_seconds": 1712102400, "_nanoseconds": 0},
      "rank": 3,
    },
    {
      "date": {"_seconds": 1712188800, "_nanoseconds": 0},
      "rank": 3,
    },
    {
      "date": {"_seconds": 1712275200, "_nanoseconds": 0},
      "rank": 3,
    },
  ],
  "user456": [
    {
      "date": {"_seconds": 1711756800, "_nanoseconds": 0},
      "rank": 2,
    },
    {
      "date": {"_seconds": 1711843200, "_nanoseconds": 0},
      "rank": 2,
    },
    {
      "date": {"_seconds": 1711929600, "_nanoseconds": 0},
      "rank": 2,
    },
    {
      "date": {"_seconds": 1712016000, "_nanoseconds": 0},
      "rank": 2,
    },
    {
      "date": {"_seconds": 1712102400, "_nanoseconds": 0},
      "rank": 2,
    },
    {
      "date": {"_seconds": 1712188800, "_nanoseconds": 0},
      "rank": 2,
    },
    {
      "date": {"_seconds": 1712275200, "_nanoseconds": 0},
      "rank": 2,
    },
  ],
};