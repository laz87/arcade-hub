$files = Get-ChildItem -Recurse -Filter *.html
foreach ($file in $files) {
    $path = $file.FullName
    $content = Get-Content $path -Raw
    $rel = $path.Substring((Get-Location).Path.Length).TrimStart('\').Replace('\\','/')
    $canonical = 'https://gamelet.site/'
    if ($rel -eq 'index.html') { $canonical = 'https://gamelet.site/' }
    elseif ($rel -like '*/index.html') { $canonical = 'https://gamelet.site/' + ($rel -replace 'index.html$','') }
    else { $canonical = 'https://gamelet.site/' + $rel }

    # add gtag defaults and anonymize_ip
    if ($content -notmatch "gtag\('consent','default'" ) {
        $content = $content -replace "(gtag\('js', new Date\(\)\);)", "$1`n  gtag('consent','default', {'ad_storage':'denied','analytics_storage':'denied'});" }
    $content = $content -replace "gtag\('config', 'G-JDJ9TGXZ7Q'\);", "gtag('config', 'G-JDJ9TGXZ7Q', { 'anonymize_ip': true });"

    # insert SEO tags
    if ($content -notmatch '<meta name="robots"') {
        $meta = @"
<!-- SEO & Crawlability -->
<meta name="description" content="Play free online puzzle, action, and Swahili learning games at Gamelet. Fun browser games for all ages.">
<meta name="keywords" content="free online games, Swahili games, puzzle games, word games, browser games, gamelet">
<meta name="author" content="Gamelet">
<meta name="robots" content="index, follow">
<link rel="canonical" href="$canonical">

<!-- Open Graph (for social sharing) -->
<meta property="og:title" content="Gamelet - Free Online Games">
<meta property="og:description" content="Play free Swahili and puzzle games online. No download needed!">
<meta property="og:image" content="https://gamelet.site/images/1.webp">
<meta property="og:url" content="$canonical">
<meta property="og:type" content="website">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Gamelet - Free Online Games">
<meta name="twitter:description" content="Play free Swahili and puzzle games online.">
<meta name="twitter:image" content="https://gamelet.site/images/1.webp">
"@
        $replacement = $meta + "`n</head>"
        $content = $content -replace '(?i)</head>', $replacement
    }

    # JSON-LD for index
    if ($rel -eq 'index.html' -and $content -notmatch '"@type": "WebSite"') {
        $jsonld = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Gamelet",
  "url": "https://gamelet.site",
  "description": "Free online puzzle and Swahili learning games.",
  "publisher": {
    "@type": "Organization",
    "name": "Gamelet",
    "logo": {
      "@type": "ImageObject",
      "url": "https://gamelet.site/images/1.webp"
    }
  },
  "potentialAction": {
    "@type": "SearchAction",
    "target": "https://gamelet.site/?q={search_term_string}",
    "query-input": "required name=search_term_string"
  }
}
</script>
"@
        $replacement = $jsonld + "`n</head>"
        $content = $content -replace '(?i)</head>', $replacement
    }

    # cookie banner
    if ($content -notmatch 'id="cookie-banner"') {
        $banner = @"
<!-- Cookie Consent Banner -->
<div id="cookie-banner" style="display:none; position:fixed; bottom:0; left:0; right:0; background:#1a1a2e; color:#fff; padding:16px 24px; z-index:9999; display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:12px; font-family:sans-serif; font-size:14px; box-shadow:0 -2px 10px rgba(0,0,0,0.3);">
  <p style="margin:0; flex:1; min-width:200px;">
    🍪 We use cookies to improve your experience and show personalized ads. By continuing, you agree to our 
    <a href="privacy-policy.html" style="color:#a78bfa;">Privacy Policy</a>.
  </p>
  <div style="display:flex; gap:10px;">
    <button onclick="acceptCookies()" style="background:#7c3aed; color:#fff; border:none; padding:10px 20px; border-radius:6px; cursor:pointer; font-weight:bold;">Accept All</button>
    <button onclick="declineCookies()" style="background:transparent; color:#ccc; border:1px solid #555; padding:10px 20px; border-radius:6px; cursor:pointer;">Decline</button>
  </div>
</div>
<script>
  function acceptCookies() {
    localStorage.setItem('cookieConsent', 'accepted');
    document.getElementById('cookie-banner').style.display = 'none';
    if(typeof gtag==='function'){ gtag('consent','update',{'ad_storage':'granted','analytics_storage':'granted'}); }
  }
  function declineCookies() {
    localStorage.setItem('cookieConsent', 'declined');
    document.getElementById('cookie-banner').style.display = 'none';
  }
  window.addEventListener('DOMContentLoaded', function() {
    if (!localStorage.getItem('cookieConsent')) {
      document.getElementById('cookie-banner').style.display = 'flex';
    }
  });
</script>
"@
        $replacement = $banner + "`n</body>"
        $content = $content -replace '(?i)</body>', $replacement
    }
    Set-Content -Path $path -Value $content
}
