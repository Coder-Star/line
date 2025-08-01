# iOS Worktest Backend API Documentation

## Overview
**Base URL:** `https://timeline-tuner-backend.soc1024.com:5003`

## Authentication
Most endpoints require an API key to be included in the request headers:
```
X-API-Key: _fAyMKD19I7PmBeTg8p_N9sbdEzJVVkqatWTNwbW26w
```

## Endpoints

### 1. Health Check
**GET** `/`

Returns basic API status information.

**Response:**
```json
{
  "message": "Work API is running",
  "port": 5003
}
```

### 2. TikTok Authentication

#### Login
**GET** `/login`

Redirects to TikTok authorization page. No parameters required.

#### Callback
**GET** `/callback`

Handles TikTok OAuth callback. Called automatically by TikTok after authorization.

**Query Parameters:**
- `access_token` (string): TikTok access token

**Response:** Redirects to frontend with success/error parameters.

### 3. Account Management

#### Switch Account
**POST** `/switch_account/{account_key}`

Switch to a different TikTok account.

**Path Parameters:**
- `account_key` (string): Account identifier

**Response:**
```json
{
  "success": true,
  "active_account": "token_abc123...xyz789",
  "auth_token": "token_abc123...xyz789"
}
```

#### Get Liked Videos
**GET** `/liked_videos`

Fetch user's liked TikTok videos.

**Headers:**
- `X-Auth-Token` (optional): Authentication token

**Response:**
```json
{
  "success": true,
  "videos": [
    {
      "id": "video_id_123",
      "desc": "Video description",
      "author": {
        "nickname": "username"
      },
      "createTime": 1640995200
    }
  ],
  "count": 25,
  "new_likes_processed": 3
}
```

### 4. YouTube Session Management

#### Store YouTube Session
**POST** `/youtube_session`

Store YouTube authentication session data for later use.

**Headers:**
- `Content-Type: application/json`

**Request Body:**
```json
{
  "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
  "origin": "https://www.youtube.com",
  "cookies": {
    "SID": "your_sid_cookie_value",
    "HSID": "your_hsid_value",
    "SSID": "your_ssid_value",
    "APISID": "your_apisid_value",
    "SAPISID": "your_sapisid_value"
  },
  "auth_user_index": 0,
  "sapisid_hash": "your_hash_value",
  "raw_cookie_header": "SID=value; HSID=value; ..."
}
```

**Required Fields:**
- `user_agent`: Browser user agent string
- `origin`: YouTube origin URL
- `cookies`: Object containing at least `SID` cookie

**Response:**
```json
{
  "success": true,
  "message": "YouTube session data stored successfully."
}
```

### 5. Sentiment Streaming

#### Sentiment Stream
**GET** `/sentiment/stream`

Server-Sent Events (SSE) stream for real-time sentiment data. Updates every 3 minutes.

**Headers:**
- `Accept: text/event-stream`

**Event Format:**
```
data: {"timestamp": "2024-01-15T10:30:00.123456", "contentMix": {"pets": 0.25, "beauty": 0.15, "gaming": 0.35, "news": 0.08, "other": 0.17}}

data: {"type": "heartbeat", "timestamp": "2024-01-15T10:31:00.123456"}
```

**Content Mix Categories:**
- `pets`: Pet/animal related content
- `beauty`: Beauty/fashion content
- `gaming`: Gaming/esports content
- `news`: News/information content
- `other`: Other content types

#### Latest Sentiment Data
**GET** `/sentiment/latest`

Get the latest sentiment data from the last 12 minutes.

**Response:**
```json
[
  {
    "timestamp": "2024-01-15T10:30:00.123456",
    "contentMix": {
      "pets": 0.25,
      "beauty": 0.15,
      "gaming": 0.35,
      "news": 0.08,
      "other": 0.17
    }
  }
]
```

### 6. Like Events

#### Like Event Webhook
**POST** `/webhook/tiktok-like`

Webhook endpoint for receiving TikTok like events.

**Request Body:**
```json
{
  "ts": "2024-01-15T10:30:00.123456Z",
  "video_id": "video_id_123",
  "author_nick": "username"
}
```

**Response:**
```json
{
  "success": true
}
```

#### Likes Stream
**GET** `/likes/stream`

SSE stream for real-time like events.

**Event Format:**
```
data: {"ts": "2024-01-15T10:30:00.123456Z", "video_id": "video_id_123", "author_nick": "username", "likes_today": 15}
```

#### Likes Statistics
**GET** `/likes/stats`

Get today's like statistics.

**Response:**
```json
{
  "likes_today": 15
}
```

## Error Responses

### 401 Unauthorized
```json
{
  "error": "API key required"
}
```

### 400 Bad Request
```json
{
  "error": "Missing required field: cookies"
}
```

### 404 Not Found
```json
{
  "error": "Account not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Error message"
}
```

## CORS Support
The API supports CORS for the following origins:
- `http://localhost:3000`

## SSL/TLS
The API supports both HTTP and HTTPS. When SSL certificates are available, HTTPS is automatically enabled.

## Rate Limiting
The API includes exponential backoff for TikTok API calls to handle rate limits gracefully.

## Database
The API uses SQLAlchemy with the following main tables:
- `Account`: TikTok account information
- `YouTubeSession`: YouTube authentication sessions
- `SentimentData`: Sentiment analysis data
- `LikeEvent`: TikTok like events

## Background Tasks
- **Sentiment Generation**: Runs every 3 minutes to generate and broadcast sentiment data
- **SSE Management**: Handles multiple concurrent SSE connections for real-time updates 
