// Mammon Protocol - Cloudflare Worker
// mam.finance landing page

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // Serve whitepaper PDF
    if (url.pathname === '/whitepaper.pdf' || url.pathname === '/whitepaper') {
      return Response.redirect('https://github.com/admin983/Mammon-Holdings-Mammon-Protocol/raw/main/docs/whitepaper.pdf', 302);
    }

    return new Response(getHTML(), {
      headers: {
        'content-type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=3600'
      }
    });
  }
};

function getHTML() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mammon Protocol - The Devil You Can Audit</title>
    <meta name="description" content="A proof-of-work cryptocurrency with partial gold backing, AI governance, and radical transparency. Monero fork using RandomX.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;600;700&family=DM+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --gold: #D4AF37;
            --gold-light: #F4D03F;
            --obsidian: #0a0a0a;
            --charcoal: #1a1a1a;
            --slate: #2a2a2a;
            --text: #e0e0e0;
            --text-muted: #888;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--obsidian);
            color: var(--text);
            line-height: 1.6;
            overflow-x: hidden;
        }

        h1, h2, h3 { font-family: 'Playfair Display', serif; }
        code, .mono { font-family: 'JetBrains Mono', monospace; }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
        }

        /* Noise overlay */
        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            opacity: 0.03;
            pointer-events: none;
            background: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
        }

        /* Hero */
        .hero {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            padding: 100px 24px;
            position: relative;
            background: radial-gradient(ellipse at center, rgba(212, 175, 55, 0.08) 0%, transparent 70%);
        }

        .hero h1 {
            font-size: clamp(3rem, 8vw, 6rem);
            font-weight: 700;
            background: linear-gradient(135deg, var(--gold) 0%, var(--gold-light) 50%, var(--gold) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 24px;
            letter-spacing: -2px;
        }

        .hero .tagline {
            font-size: clamp(1.1rem, 2.5vw, 1.5rem);
            color: var(--text-muted);
            max-width: 600px;
            margin-bottom: 40px;
        }

        .hero .quote {
            font-style: italic;
            color: var(--gold);
            font-size: 1.1rem;
            margin-bottom: 48px;
        }

        .btn-group {
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
            justify-content: center;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 16px 32px;
            border-radius: 8px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            font-size: 1rem;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--gold) 0%, var(--gold-light) 100%);
            color: var(--obsidian);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 30px rgba(212, 175, 55, 0.3);
        }

        .btn-secondary {
            border: 2px solid var(--gold);
            color: var(--gold);
            background: transparent;
        }

        .btn-secondary:hover {
            background: rgba(212, 175, 55, 0.1);
            transform: translateY(-2px);
        }

        /* Testnet Live Banner */
        .testnet-banner {
            background: linear-gradient(135deg, rgba(212, 175, 55, 0.15) 0%, rgba(212, 175, 55, 0.05) 100%);
            border: 1px solid rgba(212, 175, 55, 0.3);
            border-radius: 16px;
            padding: 40px;
            margin: 80px auto;
            max-width: 900px;
            text-align: center;
        }

        .testnet-banner .live-indicator {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(0, 255, 0, 0.1);
            border: 1px solid rgba(0, 255, 0, 0.3);
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9rem;
            color: #00ff00;
            margin-bottom: 20px;
        }

        .testnet-banner .live-indicator::before {
            content: '';
            width: 8px;
            height: 8px;
            background: #00ff00;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .testnet-banner h2 {
            font-size: 2rem;
            color: var(--gold);
            margin-bottom: 16px;
        }

        .testnet-banner p {
            color: var(--text-muted);
            margin-bottom: 24px;
        }

        .testnet-links {
            display: flex;
            gap: 16px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .testnet-link {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px 30px;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            text-decoration: none;
            transition: all 0.3s ease;
            min-width: 160px;
        }

        .testnet-link:hover {
            border-color: var(--gold);
            background: rgba(212, 175, 55, 0.05);
            transform: translateY(-4px);
        }

        .testnet-link .icon {
            font-size: 2rem;
            margin-bottom: 8px;
        }

        .testnet-link .label {
            color: var(--text);
            font-weight: 600;
        }

        .testnet-link .url {
            color: var(--text-muted);
            font-size: 0.75rem;
            margin-top: 4px;
            font-family: 'JetBrains Mono', monospace;
        }

        /* Sections */
        section {
            padding: 100px 0;
        }

        .section-title {
            font-size: clamp(2rem, 4vw, 3rem);
            text-align: center;
            margin-bottom: 60px;
            color: var(--gold);
        }

        /* Problem Grid */
        .problem-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 24px;
        }

        .problem-card {
            background: var(--charcoal);
            border: 1px solid var(--slate);
            border-radius: 12px;
            padding: 32px;
            transition: all 0.3s ease;
        }

        .problem-card:hover {
            border-color: var(--gold);
            transform: translateY(-4px);
        }

        .problem-card .year {
            font-family: 'JetBrains Mono', monospace;
            color: var(--gold);
            font-size: 0.9rem;
            margin-bottom: 12px;
        }

        .problem-card h3 {
            font-size: 1.3rem;
            margin-bottom: 12px;
        }

        .problem-card p {
            color: var(--text-muted);
            font-size: 0.95rem;
        }

        /* Solution Pillars */
        .pillars {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 32px;
        }

        .pillar {
            background: linear-gradient(180deg, var(--charcoal) 0%, var(--obsidian) 100%);
            border: 1px solid var(--slate);
            border-radius: 16px;
            padding: 40px;
            text-align: center;
            transition: all 0.3s ease;
        }

        .pillar:hover {
            border-color: var(--gold);
        }

        .pillar .icon {
            font-size: 3rem;
            margin-bottom: 20px;
        }

        .pillar h3 {
            font-size: 1.5rem;
            margin-bottom: 16px;
            color: var(--gold);
        }

        .pillar p {
            color: var(--text-muted);
        }

        /* Specs */
        .specs-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 24px;
        }

        .spec {
            background: var(--charcoal);
            border: 1px solid var(--slate);
            border-radius: 12px;
            padding: 24px;
            text-align: center;
        }

        .spec .value {
            font-family: 'Playfair Display', serif;
            font-size: 2rem;
            color: var(--gold);
            margin-bottom: 8px;
        }

        .spec .label {
            color: var(--text-muted);
            font-size: 0.9rem;
        }

        /* CTA */
        .cta {
            text-align: center;
            background: radial-gradient(ellipse at center, rgba(212, 175, 55, 0.1) 0%, transparent 70%);
            padding: 120px 24px;
        }

        .cta h2 {
            font-size: clamp(2rem, 4vw, 3rem);
            margin-bottom: 24px;
        }

        .cta p {
            color: var(--text-muted);
            max-width: 600px;
            margin: 0 auto 40px;
        }

        /* Footer */
        footer {
            padding: 60px 24px;
            text-align: center;
            border-top: 1px solid var(--slate);
        }

        .footer-links {
            display: flex;
            gap: 32px;
            justify-content: center;
            margin-bottom: 24px;
            flex-wrap: wrap;
        }

        .footer-links a {
            color: var(--text-muted);
            text-decoration: none;
            transition: color 0.3s ease;
        }

        .footer-links a:hover {
            color: var(--gold);
        }

        .footer-quote {
            font-style: italic;
            color: var(--text-muted);
            margin-bottom: 24px;
        }

        .disclaimer {
            font-size: 0.8rem;
            color: var(--text-muted);
            max-width: 800px;
            margin: 0 auto;
            opacity: 0.7;
        }

        /* Animations */
        .fade-in {
            opacity: 0;
            transform: translateY(20px);
            transition: all 0.6s ease;
        }

        .fade-in.visible {
            opacity: 1;
            transform: translateY(0);
        }

        @media (max-width: 768px) {
            .btn-group { flex-direction: column; }
            .testnet-links { flex-direction: column; align-items: center; }
            .testnet-link { width: 100%; max-width: 300px; }
        }
    </style>
</head>
<body>
    <!-- Hero -->
    <section class="hero">
        <h1>Mammon</h1>
        <p class="tagline">A cryptocurrency more transparent than your central bank</p>
        <p class="quote">"The devil you can audit."</p>
        <div class="btn-group">
            <a href="https://github.com/admin983/Mammon-Holdings-Mammon-Protocol/raw/main/docs/whitepaper.pdf" class="btn btn-primary" target="_blank">
                Read the Whitepaper
            </a>
            <a href="https://github.com/admin983/Mammon-Holdings-Mammon-Protocol" class="btn btn-secondary" target="_blank">
                View on GitHub
            </a>
        </div>
    </section>

    <!-- Testnet Live Banner -->
    <div class="container">
        <div class="testnet-banner fade-in">
            <div class="live-indicator">TESTNET LIVE</div>
            <h2>Try Mammon Today</h2>
            <p>Our testnet is live and ready for testing. Get free test MAM from the faucet and explore the blockchain.</p>
            <div class="testnet-links">
                <a href="http://34.10.218.161:8080" class="testnet-link" target="_blank">
                    <span class="icon">🔍</span>
                    <span class="label">Block Explorer</span>
                    <span class="url">:8080</span>
                </a>
                <a href="http://34.10.218.161:8081" class="testnet-link" target="_blank">
                    <span class="icon">💧</span>
                    <span class="label">Testnet Faucet</span>
                    <span class="url">:8081</span>
                </a>
                <a href="https://github.com/admin983/Mammon-Holdings-Mammon-Protocol#quick-start" class="testnet-link" target="_blank">
                    <span class="icon">📖</span>
                    <span class="label">Run a Node</span>
                    <span class="url">GitHub</span>
                </a>
            </div>
        </div>
    </div>

    <!-- Problem Section -->
    <section>
        <div class="container">
            <h2 class="section-title fade-in">The Problem With Money</h2>
            <div class="problem-grid">
                <div class="problem-card fade-in">
                    <div class="year">1971</div>
                    <h3>Gold Standard Abandoned</h3>
                    <p>Nixon closed the gold window, ending any pretense of sound money backing.</p>
                </div>
                <div class="problem-card fade-in">
                    <div class="year">2008</div>
                    <h3>Too Big To Fail</h3>
                    <p>Banks got bailouts while homeowners got foreclosures. Privatized gains, socialized losses.</p>
                </div>
                <div class="problem-card fade-in">
                    <div class="year">2020-23</div>
                    <h3>40% Money Supply Expansion</h3>
                    <p>The Fed printed more money in 3 years than in the previous 100 combined.</p>
                </div>
                <div class="problem-card fade-in">
                    <div class="year">2023</div>
                    <h3>FDIC: 0.82% Reserve</h3>
                    <p>Your "insured" deposits are backed by less than 1 cent on the dollar.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Solution Section -->
    <section>
        <div class="container">
            <h2 class="section-title fade-in">Our Solution</h2>
            <div class="pillars">
                <div class="pillar fade-in">
                    <div class="icon">🥇</div>
                    <h3>Gold Backing</h3>
                    <p>15% of protocol revenue goes to CME gold futures, creating real-world backing that grows with adoption.</p>
                </div>
                <div class="pillar fade-in">
                    <div class="icon">🤖</div>
                    <h3>AI Governors</h3>
                    <p>Five elected AI agents manage the treasury with algorithmic rules and transparent decision-making.</p>
                </div>
                <div class="pillar fade-in">
                    <div class="icon">🔍</div>
                    <h3>Radical Transparency</h3>
                    <p>Every transaction, every treasury action, every decision is on-chain and auditable by anyone.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Specs Section -->
    <section>
        <div class="container">
            <h2 class="section-title fade-in">Technical Specs</h2>
            <div class="specs-grid">
                <div class="spec fade-in">
                    <div class="value">RandomX</div>
                    <div class="label">Mining Algorithm</div>
                </div>
                <div class="spec fade-in">
                    <div class="value">120s</div>
                    <div class="label">Block Time</div>
                </div>
                <div class="spec fade-in">
                    <div class="value">85/10/5</div>
                    <div class="label">Miner/Treasury/Insurance</div>
                </div>
                <div class="spec fade-in">
                    <div class="value">0</div>
                    <div class="label">Premine</div>
                </div>
                <div class="spec fade-in">
                    <div class="value">LWMA</div>
                    <div class="label">Difficulty Algorithm</div>
                </div>
                <div class="spec fade-in">
                    <div class="value">Monero</div>
                    <div class="label">Fork Base</div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA -->
    <section class="cta">
        <div class="container">
            <h2 class="fade-in">Ready to Join?</h2>
            <p class="fade-in">Start mining on testnet, explore the code, or read the whitepaper to learn more.</p>
            <div class="btn-group fade-in">
                <a href="http://34.10.218.161:8081" class="btn btn-primary" target="_blank">
                    Get Test MAM
                </a>
                <a href="https://github.com/admin983/Mammon-Holdings-Mammon-Protocol" class="btn btn-secondary" target="_blank">
                    View Source Code
                </a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-links">
            <a href="https://github.com/admin983/Mammon-Holdings-Mammon-Protocol" target="_blank">GitHub</a>
            <a href="http://34.10.218.161:8080" target="_blank">Block Explorer</a>
            <a href="http://34.10.218.161:8081" target="_blank">Faucet</a>
            <a href="https://twitter.com/MammonProtocol" target="_blank">Twitter</a>
            <a href="mailto:confessions@mam.finance">confessions@mam.finance</a>
        </div>
        <p class="footer-quote">"I might be a demon, but at least my couch feels good." - Mammon</p>
        <p class="disclaimer">
            This is experimental software. Testnet coins have no value.
            Not financial advice. Do your own research. The devil is in the details.
        </p>
    </footer>

    <script>
        // Intersection Observer for fade-in animations
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                }
            });
        }, { threshold: 0.1 });

        document.querySelectorAll('.fade-in').forEach(el => observer.observe(el));
    </script>
</body>
</html>`;
}
