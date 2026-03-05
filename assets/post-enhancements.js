(function () {
  var article = document.querySelector("article");
  if (!article) {
    return;
  }

  function countWords(text) {
    var tokens = text.trim().match(/[A-Za-z0-9][A-Za-z0-9'-]*/g);
    return tokens ? tokens.length : 0;
  }

  function toIsoDurationMinutes(minutes) {
    return "PT" + String(Math.max(1, minutes)) + "M";
  }

  var articleText = article.textContent || "";
  var wordCount = countWords(articleText);
  var readMinutes = Math.max(1, Math.ceil(wordCount / 220));
  var readLabel = String(readMinutes) + " min read";

  var readSpan = null;
  var spans = Array.prototype.slice.call(document.querySelectorAll(".meta span, .hero-meta span"));
  for (var i = 0; i < spans.length; i += 1) {
    if (/min read/i.test(spans[i].textContent)) {
      readSpan = spans[i];
      break;
    }
  }
  if (readSpan) {
    readSpan.textContent = readLabel;
  }

  var schemaEl = document.querySelector("script[type='application/ld+json'][data-post-schema]");
  if (schemaEl) {
    try {
      var schemaData = JSON.parse(schemaEl.textContent);
      schemaData.wordCount = wordCount;
      schemaData.timeRequired = toIsoDurationMinutes(readMinutes);
      schemaEl.textContent = JSON.stringify(schemaData, null, 2);
    } catch (err) {
      // Ignore invalid schema payload; keep page rendering unaffected.
    }
  }

  // TOC intentionally disabled across all posts.
})();
