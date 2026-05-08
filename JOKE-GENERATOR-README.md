# Random Joke Generator 🎭

This project contains multiple implementations of a random joke generator using the **JokeAPI** (https://jokeapi.dev/).

## Available Implementations

### 1. **JavaScript/Node.js** (`joke-generator.js`)
A Node.js implementation using the built-in `https` module.

**Features:**
- Fetch random jokes without external dependencies
- Support for single and two-part jokes
- Safe mode to filter offensive content
- Promise-based async/await support
- Can be used as a module

**Usage:**
```bash
node joke-generator.js
```

**As a module:**
```javascript
const { getRandomJoke, displayJoke } = require('./joke-generator.js');

getRandomJoke({ type: 'any', safe: true })
  .then(joke => displayJoke(joke))
  .catch(error => console.error(error));
```

---

### 2. **Python** (`joke-generator.py`)
A Python implementation using the `requests` library.

**Features:**
- Object-oriented design with JokeGenerator class
- Command-line arguments for customization
- Error handling with informative messages
- Type hints for better code clarity
- Configurable safe mode

**Installation:**
```bash
pip install requests
```

**Usage:**
```bash
# Get a random joke (default: safe mode, any type)
python joke-generator.py

# Get only single-line jokes
python joke-generator.py --type single

# Get two-part jokes without safe mode
python joke-generator.py --type twopart --unsafe

# Get any type of joke without safe mode
python joke-generator.py --unsafe
```

---

### 3. **Web Browser** (`joke-generator-web.html`)
A fully interactive web-based joke generator.

**Features:**
- Beautiful gradient UI with modern design
- Real-time joke fetching
- Select joke type (Any, Single, Two-part)
- Toggle safe mode on/off
- Responsive design (mobile-friendly)
- Shows joke category
- Loading states and error handling
- Keyboard support (Enter key to fetch)

**Usage:**
Simply open the HTML file in any web browser:
```bash
# On macOS
open joke-generator-web.html

# On Linux
firefox joke-generator-web.html

# On Windows
start joke-generator-web.html
```

Or access it via any HTTP server:
```bash
python -m http.server 8000
# Then visit: http://localhost:8000/joke-generator-web.html
```

---

## API Details

**Endpoint:** `https://v2.jokeapi.dev/joke/{type}`

**Parameters:**
- `type` - Type of joke:
  - `any` - Random single or two-part joke
  - `single` - Single-line jokes only
  - `twopart` - Two-part jokes only
  - `general`, `knock-knock`, `programming`, etc. - Specific categories

- `safe-mode=true|false` - Filter offensive content (default: false)

- `blacklistFlags` - Exclude specific content types:
  - `nsfw` - Not safe for work
  - `religious` - Religious content
  - `political` - Political content
  - `racist` - Racist content
  - `sexist` - Sexist content
  - `explicit` - Explicit language

**Example Response (Two-part):**
```json
{
  "error": false,
  "category": "Programming",
  "type": "twopart",
  "setup": "How many programmers does it take to change a light bulb?",
  "delivery": "None, that's a hardware problem!",
  "flags": {
    "nsfw": false,
    "religious": false,
    "political": false,
    "racist": false,
    "sexist": false,
    "explicit": false
  },
  "id": 1,
  "safe": true,
  "lang": "en"
}
```

---

## Joke Categories

- **Any** - Random from all categories
- **General** - General/miscellaneous jokes
- **Knock-Knock** - Classic knock-knock jokes
- **Programming** - Programming and tech jokes
- **Dark** - Dark humor jokes

---

## API Rate Limiting

JokeAPI has rate limiting to prevent abuse:
- **Rate Limit:** 120 requests per minute
- **Burst Limit:** 10 requests in 10 seconds

For more information, visit: https://jokeapi.dev/

---

## Error Handling

All implementations include proper error handling:
- Network timeouts
- Invalid API responses
- JSON parsing errors
- API error responses

---

## Requirements

| Implementation | Requirements |
|---|---|
| JavaScript | Node.js 10+ (built-in modules only) |
| Python | Python 3.6+, `requests` library |
| Web | Modern web browser (ES6 support) |

---

## License

These implementations are provided as examples for educational purposes.
JokeAPI is developed by Sv. Jough and is free to use.

---

## References

- **JokeAPI:** https://jokeapi.dev/
- **Node.js HTTPS Module:** https://nodejs.org/api/https.html
- **Python Requests:** https://requests.readthedocs.io/

---

## Tips & Tricks

1. **Caching Results:** Store fetched jokes in a file to reduce API calls
2. **Scheduling:** Use cron jobs (Linux/macOS) or Task Scheduler (Windows) to get daily jokes
3. **Webhooks:** Integrate with Slack, Discord, or other services for automatic joke delivery
4. **Database:** Store jokes in a database for offline access or custom filtering

---

**Created:** 2026-05-08
**Author:** Joke Generator Contributors
