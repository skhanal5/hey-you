let defaultDoomscrollSignatures: [DoomscrollSignature] = [
    DoomscrollSignature(name: "X/Twitter",   patterns: ["\\bX\\b", "Twitter"],        threshold: 30,  repeatThreshold: 15),
    DoomscrollSignature(name: "Reddit",      patterns: ["\\bReddit\\b"],              threshold: 30,  repeatThreshold: 15),
    DoomscrollSignature(name: "Instagram",   patterns: ["\\bInstagram\\b"],           threshold: 20,  repeatThreshold: 10),
    DoomscrollSignature(name: "TikTok",      patterns: ["\\bTikTok\\b"],              threshold: 20,  repeatThreshold: 10),
    DoomscrollSignature(name: "YouTube",     patterns: ["\\bYouTube\\b"],             threshold: 45,  repeatThreshold: 20),
    DoomscrollSignature(name: "Facebook",    patterns: ["\\bFacebook\\b"],            threshold: 30,  repeatThreshold: 15),
    DoomscrollSignature(name: "Bluesky",     patterns: ["\\bBluesky\\b"],             threshold: 30,  repeatThreshold: 15),
    DoomscrollSignature(name: "Threads",     patterns: ["\\bThreads\\b"],             threshold: 30,  repeatThreshold: 15),
    DoomscrollSignature(name: "LinkedIn",    patterns: ["\\bLinkedIn\\b"],            threshold: 45,  repeatThreshold: 30),
    DoomscrollSignature(name: "Twitch",      patterns: ["\\bTwitch\\b"],              threshold: 45,  repeatThreshold: 30),
]
