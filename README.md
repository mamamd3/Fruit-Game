<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FRUIT GAME — Plan Działania</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Mono:wght@400;500&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
	--bg: #0e0e0e;
	--surface: #141414;
	--card: #1a1a1a;
	--border: #272727;
	--border-bright: #383838;
	--accent-red: #ff4d4d;
	--accent-yellow: #ffd426;
	--accent-green: #52e05e;
	--accent-orange: #ff8c42;
	--accent-purple: #c084fc;
	--accent-blue: #60c8ff;
	--accent-pink: #ff6fb0;
	--text: #efefef;
	--muted: #777;
	--muted2: #555;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
	background: var(--bg);
	color: var(--text);
	font-family: 'DM Sans', sans-serif;
	font-size: 14px;
	line-height: 1.65;
  }

  /* ─── HERO ─────────────────────────────────────────── */
  .hero {
	background: var(--surface);
	border-bottom: 1px solid var(--border);
	padding: 56px 40px 48px;
	position: relative;
	overflow: hidden;
  }

  .hero::before {
	content: '';
	position: absolute;
	inset: 0;
	background:
	  radial-gradient(ellipse 60% 80% at 10% 50%, rgba(255,212,38,0.05) 0%, transparent 70%),
	  radial-gradient(ellipse 40% 60% at 90% 30%, rgba(82,224,94,0.04) 0%, transparent 70%);
	pointer-events: none;
  }

  .hero-grid {
	position: absolute;
	inset: 0;
	background-image:
	  linear-gradient(var(--border) 1px, transparent 1px),
	  linear-gradient(90deg, var(--border) 1px, transparent 1px);
	background-size: 48px 48px;
	opacity: 0.25;
	pointer-events: none;
	mask-image: radial-gradient(ellipse at 50% 50%, black 20%, transparent 70%);
  }

  .hero-inner {
	max-width: 860px;
	margin: 0 auto;
	position: relative;
  }

  .tag-row {
	display: flex;
	gap: 8px;
	flex-wrap: wrap;
	margin-bottom: 24px;
  }

  .pill {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	border-radius: 99px;
	padding: 3px 11px;
	font-size: 10px;
	letter-spacing: 1.2px;
	text-transform: uppercase;
	font-weight: 600;
	border: 1px solid var(--border-bright);
	color: var(--muted);
	background: transparent;
  }

  .pill.live { border-color: rgba(82,224,94,0.35); color: var(--accent-green); }
  .pill.live::before { content: '●'; margin-right: 2px; font-size: 8px; }

  h1 {
	font-family: 'Syne', sans-serif;
	font-size: clamp(2.4rem, 5.5vw, 4.4rem);
	font-weight: 800;
	line-height: 1;
	letter-spacing: -2px;
	margin-bottom: 10px;
  }

  h1 em {
	font-style: normal;
	color: var(--accent-yellow);
  }

  .hero-sub {
	color: var(--muted);
	font-size: 13px;
	max-width: 480px;
	margin-top: 12px;
  }

  .hero-stats {
	display: flex;
	gap: 32px;
	margin-top: 32px;
	flex-wrap: wrap;
  }

  .hstat { display: flex; flex-direction: column; gap: 1px; }
  .hstat-label { font-size: 10px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted2); }
  .hstat-val { font-size: 13px; font-weight: 600; }

  /* ─── LAYOUT ────────────────────────────────────────── */
  .wrap {
	max-width: 860px;
	margin: 0 auto;
	padding: 0 24px 80px;
  }

  /* ─── PHASE ─────────────────────────────────────────── */
  .phase {
	margin-top: 44px;
  }

  .phase-header {
	display: grid;
	grid-template-columns: auto 1fr auto;
	align-items: center;
	gap: 14px;
	margin-bottom: 16px;
	padding-bottom: 14px;
	border-bottom: 1px solid var(--border);
  }

  .phase-num {
	font-family: 'DM Mono', monospace;
	font-size: 11px;
	color: var(--muted2);
	letter-spacing: 1px;
  }

  .phase-title {
	font-family: 'Syne', sans-serif;
	font-size: 1.1rem;
	font-weight: 700;
	letter-spacing: -0.3px;
  }

  .phase-badge {
	font-size: 10px;
	font-weight: 600;
	letter-spacing: 1px;
	text-transform: uppercase;
	padding: 3px 10px;
	border-radius: 6px;
	white-space: nowrap;
  }

  .badge-mvp    { background: rgba(82,224,94,0.1);  color: var(--accent-green);  border: 1px solid rgba(82,224,94,0.2); }
  .badge-v1     { background: rgba(255,212,38,0.08); color: var(--accent-yellow); border: 1px solid rgba(255,212,38,0.2); }
  .badge-v2     { background: rgba(255,140,66,0.08); color: var(--accent-orange); border: 1px solid rgba(255,140,66,0.2); }
  .badge-polish { background: rgba(192,132,252,0.08);color: var(--accent-purple); border: 1px solid rgba(192,132,252,0.2);}

  /* ─── TASK LIST ─────────────────────────────────────── */
  .task-list {
	display: flex;
	flex-direction: column;
	gap: 6px;
  }

  .task {
	display: grid;
	grid-template-columns: 28px 1fr auto;
	align-items: flex-start;
	gap: 10px;
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: 9px;
	padding: 12px 14px;
	transition: border-color .15s;
  }

  .task:hover { border-color: var(--border-bright); }

  .task-n {
	font-family: 'DM Mono', monospace;
	font-size: 11px;
	color: var(--muted2);
	padding-top: 1px;
	user-select: none;
  }

  .task-body { display: flex; flex-direction: column; gap: 3px; }

  .task-name {
	font-size: 13px;
	font-weight: 600;
	color: var(--text);
	line-height: 1.4;
  }

  .task-desc {
	font-size: 12px;
	color: var(--muted);
	line-height: 1.5;
  }

  .task-tag {
	font-size: 10px;
	letter-spacing: 0.8px;
	text-transform: uppercase;
	padding: 2px 7px;
	border-radius: 4px;
	font-weight: 600;
	white-space: nowrap;
	align-self: flex-start;
	margin-top: 1px;
  }

  .tt-core    { background: rgba(96,200,255,0.08); color: var(--accent-blue);   border: 1px solid rgba(96,200,255,0.18); }
  .tt-ui      { background: rgba(255,110,176,0.08); color: var(--accent-pink);  border: 1px solid rgba(255,110,176,0.18);}
  .tt-sys     { background: rgba(255,212,38,0.08);  color: var(--accent-yellow);border: 1px solid rgba(255,212,38,0.18); }
  .tt-design  { background: rgba(192,132,252,0.08); color: var(--accent-purple);border: 1px solid rgba(192,132,252,0.18);}
  .tt-net     { background: rgba(82,224,94,0.08);   color: var(--accent-green); border: 1px solid rgba(82,224,94,0.18); }
  .tt-audio   { background: rgba(255,140,66,0.08);  color: var(--accent-orange);border: 1px solid rgba(255,140,66,0.18);}
  .tt-vfx     { background: rgba(255,77,77,0.08);   color: var(--accent-red);   border: 1px solid rgba(255,77,77,0.18); }

  /* ─── SUB-ITEMS ─────────────────────────────────────── */
  .sub-items {
	display: flex;
	flex-wrap: wrap;
	gap: 5px;
	margin-top: 6px;
  }

  .sub-item {
	display: inline-flex;
	align-items: center;
	gap: 4px;
	background: var(--surface);
	border: 1px solid var(--border);
	border-radius: 5px;
	padding: 2px 8px;
	font-size: 11px;
	color: #aaa;
  }

  .sub-item-icon { font-size: 12px; }

  /* ─── LEGEND ─────────────────────────────────────────── */
  .legend {
	display: flex;
	gap: 10px;
	flex-wrap: wrap;
	margin-top: 28px;
	padding: 16px 18px;
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: 10px;
	align-items: center;
  }

  .legend-label {
	font-size: 10px;
	text-transform: uppercase;
	letter-spacing: 1px;
	color: var(--muted2);
	margin-right: 4px;
	font-weight: 600;
  }

  /* ─── PHASE DIVIDER ─────────────────────────────────── */
  .divider {
	height: 1px;
	background: linear-gradient(90deg, transparent, var(--border), transparent);
	margin-top: 44px;
  }

  /* ─── FOOTER ─────────────────────────────────────────── */
  .footer {
	margin-top: 56px;
	padding-top: 24px;
	border-top: 1px solid var(--border);
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: 12px;
  }

  .footer-l { font-size: 11px; color: var(--muted2); }
  .footer-l b { color: var(--muted); }
  .ver {
	font-family: 'DM Mono', monospace;
	font-size: 10px;
	color: var(--muted2);
	background: var(--surface);
	border: 1px solid var(--border);
	border-radius: 4px;
	padding: 3px 8px;
  }
</style>
</head>
<body>

<div class="hero">
  <div class="hero-grid"></div>
  <div class="hero-inner">
	<div class="tag-row">
	  <span class="pill live">Aktywny projekt</span>
	  <span class="pill">Game Design Document</span>
	  <span class="pill">Roadmapa v1.0</span>
	</div>

	<h1><em>FRUIT GAME</em><br>Plan Działania</h1>
	<p class="hero-sub">
	  Co po kolei budować — od fundamentów silnika aż po pełny polish. Każda faza jest niezależna i grywalnym krokiem naprzód.
	</p>

	<div class="hero-stats">
	  <div class="hstat">
		<span class="hstat-label">Fazy</span>
		<span class="hstat-val">7 faz</span>
	  </div>
	  <div class="hstat">
		<span class="hstat-label">Zadania</span>
		<span class="hstat-val">30 zadań</span>
	  </div>
	  <div class="hstat">
		<span class="hstat-label">MVP po</span>
		<span class="hstat-val">Fazie 0</span>
	  </div>
	  <div class="hstat">
		<span class="hstat-label">Tryb</span>
		<span class="hstat-val">Lokalny → Sieciowy</span>
	  </div>
	</div>
  </div>
</div>

<div class="wrap">

  <!-- LEGENDA -->
  <div class="legend">
	<span class="legend-label">Kategorie:</span>
	<span class="task-tag tt-core">Core</span>
	<span class="task-tag tt-ui">UI</span>
	<span class="task-tag tt-sys">System</span>
	<span class="task-tag tt-design">Design</span>
	<span class="task-tag tt-vfx">VFX</span>
	<span class="task-tag tt-audio">Audio</span>
	<span class="task-tag tt-net">Sieć</span>
  </div>

  <!-- ══ FAZA 0 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 00</span>
	  <span class="phase-title">Fundament — MVP</span>
	  <span class="phase-badge badge-mvp">MVP</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">01</span>
		<div class="task-body">
		  <span class="task-name">Silnik fizyki i ruchu</span>
		  <span class="task-desc">Poruszanie się owocka (8 kierunków / analog), kolizje ze ścianami i innymi owockami.</span>
		</div>
		<span class="task-tag tt-core">Core</span>
	  </div>

	  <div class="task">
		<span class="task-n">02</span>
		<div class="task-body">
		  <span class="task-name">System strzelania</span>
		  <span class="task-desc">Bazowy pocisk, kierunek celowania myszką / prawym analogiem, cooldown strzelania.</span>
		</div>
		<span class="task-tag tt-core">Core</span>
	  </div>

	  <div class="task">
		<span class="task-n">03</span>
		<div class="task-body">
		  <span class="task-name">4 postacie z unikalnymi statystykami</span>
		  <span class="task-desc">HP, speed, DMG, range, fire rate — każda postać z wyraźnie inną rolą.</span>
		  <div class="sub-items">
			<span class="sub-item"><span class="sub-item-icon">🍓</span> Truskawka — Wszechstronny</span>
			<span class="sub-item"><span class="sub-item-icon">🍇</span> Winogrono — Szybkostrzelny</span>
			<span class="sub-item"><span class="sub-item-icon">🍍</span> Ananas — Tank</span>
			<span class="sub-item"><span class="sub-item-icon">🍊</span> Pomarańcza — Snajper</span>
		  </div>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	  <div class="task">
		<span class="task-n">04</span>
		<div class="task-body">
		  <span class="task-name">1 statyczna mapa testowa</span>
		  <span class="task-desc">Prosta arena z przeszkodami i 4 symetrycznymi spawn pointami. Tylko do testów MVP.</span>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	  <div class="task">
		<span class="task-n">05</span>
		<div class="task-body">
		  <span class="task-name">Mechanika gnicia</span>
		  <span class="task-desc">Każdy owocek traci HP co X sekund. Tempo gnicia rośnie z czasem rundy — eliminuje "siedzenie w krzakach".</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">06</span>
		<div class="task-body">
		  <span class="task-name">Koniec rundy i ranking</span>
		  <span class="task-desc">Warunek wygranej: ostatni żywy owocek. Remis — ranking według ostatniego HP. Wynik 1–4.</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">07</span>
		<div class="task-body">
		  <span class="task-name">Ekran wyboru postaci (lokalnie)</span>
		  <span class="task-desc">2–4 graczy na klawiaturze lub padach. Każdy gracz wybiera owocka przed rundą.</span>
		</div>
		<span class="task-tag tt-ui">UI</span>
	  </div>

	  <div class="task">
		<span class="task-n">08</span>
		<div class="task-body">
		  <span class="task-name">Podstawowe HUD</span>
		  <span class="task-desc">Paski HP nad owockami, timer rundy, wskaźnik tempa gnicia. Wyraźny, czytelny w chaosie walki.</span>
		</div>
		<span class="task-tag tt-ui">UI</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 1 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 01</span>
	  <span class="phase-title">System modyfikatorów i rund</span>
	  <span class="phase-badge badge-v1">v1.0</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">09</span>
		<div class="task-body">
		  <span class="task-name">Ekran wyboru modyfikatora po rundzie</span>
		  <span class="task-desc">Gracze 3. i 4. wybierają 1 z 3 losowych kart. Miejsca 1 i 2 — brak ulepszenia (anty-snowball). Kolejność: od ostatniego.</span>
		</div>
		<span class="task-tag tt-ui">UI</span>
	  </div>

	  <div class="task">
		<span class="task-n">10</span>
		<div class="task-body">
		  <span class="task-name">Implementacja 8 modyfikatorów</span>
		  <span class="task-desc">Każdy modyfikator trwa przez całą kolejną rundę. Stackują się z kolejnych rund.</span>
		  <div class="sub-items">
			<span class="sub-item">↩️ Odbijające pociski</span>
			<span class="sub-item">👟 +20% prędkość</span>
			<span class="sub-item">☠️ Ślad trucizny</span>
			<span class="sub-item">🔴 Kradzież HP</span>
			<span class="sub-item">💣 Eksplodujące pociski</span>
			<span class="sub-item">🐌 Lepkie pociski</span>
			<span class="sub-item">🛡️ Pancerz</span>
			<span class="sub-item">🌪️ Wirujące pociski</span>
		  </div>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">11</span>
		<div class="task-body">
		  <span class="task-name">System rund i ekran końcowy meczu</span>
		  <span class="task-desc">Mecz = 5 rund. Punkty zbierane po każdej rundzie (1. miejsce = 4 pkt, 4. = 1 pkt). Ekran końcowy z sumarycznym rankingiem i wyróżnieniem zwycięzcy.</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 2 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 02</span>
	  <span class="phase-title">Pula map</span>
	  <span class="phase-badge badge-v1">v1.0</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">12</span>
		<div class="task-body">
		  <span class="task-name">Stworzenie 4–6 ręcznie zaprojektowanych map</span>
		  <span class="task-desc">Każda mapa: 4 otwarte przestrzenie + wąskie korytarze. Różne charaktery: otwarta, klaustrofobiczna, symetryczna, labirynt.</span>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	  <div class="task">
		<span class="task-n">13</span>
		<div class="task-body">
		  <span class="task-name">System losowego wyboru mapy</span>
		  <span class="task-desc">Losowanie na start każdej rundy. Brak powtórzeń z poprzedniej rundy. Krótki ekran zapowiedzi mapy.</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">14</span>
		<div class="task-body">
		  <span class="task-name">Symetryczne spawn pointy i balans map</span>
		  <span class="task-desc">Każdy gracz startuje w równej odległości od centrum i od wrogów. Testy czy żadna mapa nie faworyzuje konkretnej postaci.</span>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 3 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 03</span>
	  <span class="phase-title">Umiejętności specjalne owocków</span>
	  <span class="phase-badge badge-v1">v1.0</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">15</span>
		<div class="task-body">
		  <span class="task-name">Mechanika umiejętności (cooldown i input)</span>
		  <span class="task-desc">Przycisk umiejętności, czas ładowania (cooldown), blokada podczas animacji. Wskaźnik cooldownu w HUD.</span>
		</div>
		<span class="task-tag tt-core">Core</span>
	  </div>

	  <div class="task">
		<span class="task-n">16</span>
		<div class="task-body">
		  <span class="task-name">Implementacja 4 umiejętności</span>
		  <span class="task-desc">Każda umiejętność z unikalną logiką i wizualnym feedbackiem.</span>
		  <div class="sub-items">
			<span class="sub-item">🍓 Dash — zryw w kierunku ruchu</span>
			<span class="sub-item">🍇 Grad winogron — burst fire</span>
			<span class="sub-item">🍍 Kolce — radialny strzał dookoła</span>
			<span class="sub-item">🍊 Fokus — pocisk przebija ściany</span>
		  </div>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 4 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 04</span>
	  <span class="phase-title">Mechanika soku (Hit Effects)</span>
	  <span class="phase-badge badge-v1">v1.0</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">17</span>
		<div class="task-body">
		  <span class="task-name">System plam soku po trafieniu</span>
		  <span class="task-desc">Po uderzeniu owocek wyrzuca plamę soku w losowym kierunku. Plama ląduje na ziemi i ma aktywny efekt przez kilka sekund, następnie zanika.</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">18</span>
		<div class="task-body">
		  <span class="task-name">Efekty plam per postać</span>
		  <span class="task-desc">Każda plama ma inny kolor i efekt — dodaje strategię kontroli terenu.</span>
		  <div class="sub-items">
			<span class="sub-item">🍓 Czerwony — lekkie spowolnienie</span>
			<span class="sub-item">🍇 Fioletowy — spowolnienie 1.5s</span>
			<span class="sub-item">🍍 Żółty — DoT (obrażenia w czasie)</span>
			<span class="sub-item">🍊 Pomarańczowy — zmniejszony zasięg 2s</span>
		  </div>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">19</span>
		<div class="task-body">
		  <span class="task-name">Animacja zanikania plam</span>
		  <span class="task-desc">Kolor plamy blednie przed zniknięciem — gracze widzą kiedy efekt wygasa. Limit aktywnych plam żeby nie zalewać mapy.</span>
		</div>
		<span class="task-tag tt-vfx">VFX</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 5 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 05</span>
	  <span class="phase-title">Super-ulepszenia dla ostatniego gracza</span>
	  <span class="phase-badge badge-v2">v2.0</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">20</span>
		<div class="task-body">
		  <span class="task-name">Trigger Super-ulepszenia</span>
		  <span class="task-desc">Co X rund gracz na ostatnim miejscu dostaje Super-ulepszenie zamiast zwykłego modyfikatora. Wyraźny komunikat z animacją.</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">21</span>
		<div class="task-body">
		  <span class="task-name">Implementacja 3 Super-ulepszeń</span>
		  <span class="task-desc">Potężne efekty zmieniające styl gry — wyrównują szanse bez gwarantowania wygranej.</span>
		  <div class="sub-items">
			<span class="sub-item">🔥 Chili — palenie przy każdym ataku</span>
			<span class="sub-item">🧊 Zamrożenie — późniejsze gnicie</span>
			<span class="sub-item">☢️ Radioaktywny — aura spowalniająca wrogów</span>
		  </div>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">22</span>
		<div class="task-body">
		  <span class="task-name">Wizualna transformacja owocka</span>
		  <span class="task-desc">Owocek zmienia kolor, ma cząsteczki/aurę wokół siebie. Inni gracze muszą od razu wiedzieć że muszą uważać.</span>
		</div>
		<span class="task-tag tt-vfx">VFX</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 6 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 06</span>
	  <span class="phase-title">Mutatory mapy</span>
	  <span class="phase-badge badge-v2">v2.0</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">23</span>
		<div class="task-body">
		  <span class="task-name">System mutatora — losowanie na start rundy</span>
		  <span class="task-desc">Szansa ~25% na aktywację mutatora. Komunikat na ekranie przed startem: "Ta runda: LODOWA MAPA 🧊". Mutator dotyczy wszystkich graczy jednakowo.</span>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	  <div class="task">
		<span class="task-n">24</span>
		<div class="task-body">
		  <span class="task-name">Implementacja 5 mutatorów</span>
		  <span class="task-desc">Każdy mutator drastycznie zmienia dynamikę rundy.</span>
		  <div class="sub-items">
			<span class="sub-item">☄️ Deszcz meteorytów</span>
			<span class="sub-item">🔥 Płonące strefy (kurczące się)</span>
			<span class="sub-item">🧊 Lodowa mapa (poślizg)</span>
			<span class="sub-item">🔬 Mikro / Makro (zmiana rozmiaru)</span>
			<span class="sub-item">🌑 Ciemność (ograniczone pole widzenia)</span>
		  </div>
		</div>
		<span class="task-tag tt-sys">System</span>
	  </div>

	</div>
  </div>

  <!-- ══ FAZA 7 ══════════════════════════════════════════ -->
  <div class="phase">
	<div class="phase-header">
	  <span class="phase-num">FAZA 07</span>
	  <span class="phase-title">Polish, balans i rozszerzenia</span>
	  <span class="phase-badge badge-polish">Polish</span>
	</div>
	<div class="task-list">

	  <div class="task">
		<span class="task-n">25</span>
		<div class="task-body">
		  <span class="task-name">Efekty dźwiękowe</span>
		  <span class="task-desc">Strzały, trafienia, śmierć owocka, aktywacja umiejętności, pick modyfikatora, gnicie (bulgotanie), Super-ulepszenie.</span>
		</div>
		<span class="task-tag tt-audio">Audio</span>
	  </div>

	  <div class="task">
		<span class="task-n">26</span>
		<div class="task-body">
		  <span class="task-name">Efekty cząsteczkowe (VFX)</span>
		  <span class="task-desc">Sok tryskający po trafieniu, animacja gnicia (owocek ciemnieje), eksplozje pocisków, efekty umiejętności, Super-ulepszenie aura.</span>
		</div>
		<span class="task-tag tt-vfx">VFX</span>
	  </div>

	  <div class="task">
		<span class="task-n">27</span>
		<div class="task-body">
		  <span class="task-name">Balans statystyk na podstawie testów</span>
		  <span class="task-desc">HP, DMG, cooldowny, tempo gnicia, wartości modyfikatorów — każda postać powinna mieć równe szanse wygranej przy dobrym graniu.</span>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	  <div class="task">
		<span class="task-n">28</span>
		<div class="task-body">
		  <span class="task-name">Nowe motywy map (opcja)</span>
		  <span class="task-desc">Predefiniowane tematy: las, miasto, kosmos — z losowym układem przeszkód w ramach każdego motywu.</span>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	  <div class="task">
		<span class="task-n">29</span>
		<div class="task-body">
		  <span class="task-name">Nowa postać: Banan 🍌</span>
		  <span class="task-desc">Rola sabotażysty — rzuca skórkami, które spowalniają wrogów przy nadepnięciu. Unikalna mechanika kontroli terenu.</span>
		</div>
		<span class="task-tag tt-design">Design</span>
	  </div>

	  <div class="task">
		<span class="task-n">30</span>
		<div class="task-body">
		  <span class="task-name">Tryb sieciowy (multiplayer online)</span>
		  <span class="task-desc">Synchronizacja pozycji, pocisków i efektów przez sieć. Lobby, matchmaking lub prywatne pokoje z kodem.</span>
		</div>
		<span class="task-tag tt-net">Sieć</span>
	  </div>

	</div>
  </div>

  <!-- FOOTER -->
  <div class="footer">
	<div class="footer-l">
	  <b>Fruit Game</b> — Plan Działania &nbsp;·&nbsp; Projekt własny
	</div>
	<span class="ver">roadmap v1.0 · 2025</span>
  </div>

</div>
</body>
</html>****
