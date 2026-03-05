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

  if (document.body && document.body.hasAttribute("data-disable-toc")) {
    return;
  }

  var headings = Array.prototype.slice.call(article.querySelectorAll("h2, h3"));
  if (wordCount < 900 || headings.length < 4) {
    return;
  }

  function slugify(value) {
    return value
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .trim()
      .replace(/\s+/g, "-");
  }

  var usedIds = Object.create(null);
  var tocItems = [];
  headings.forEach(function (heading) {
    var text = (heading.textContent || "").trim();
    if (!text) {
      return;
    }
    var base = heading.id ? heading.id : slugify(text);
    if (!base) {
      return;
    }
    var candidate = base;
    var idx = 2;
    while (usedIds[candidate] || document.getElementById(candidate)) {
      candidate = base + "-" + String(idx);
      idx += 1;
    }
    usedIds[candidate] = true;
    if (!heading.id) {
      heading.id = candidate;
    }
    tocItems.push({
      id: heading.id,
      text: text,
      level: heading.tagName.toLowerCase()
    });
  });

  if (!tocItems.length) {
    return;
  }

  var toc = document.createElement("nav");
  toc.className = "post-toc";
  toc.setAttribute("aria-label", "Table of contents");
  toc.innerHTML = "<p class=\"post-toc-title\">On This Page</p>";

  var list = document.createElement("ul");
  list.className = "post-toc-list";
  tocItems.forEach(function (item) {
    var li = document.createElement("li");
    var a = document.createElement("a");
    a.className = "post-toc-link depth-" + (item.level === "h3" ? "3" : "2");
    a.href = "#" + item.id;
    a.textContent = item.text;
    li.appendChild(a);
    list.appendChild(li);
  });
  toc.appendChild(list);
  document.body.appendChild(toc);

  var tocLinks = Array.prototype.slice.call(toc.querySelectorAll(".post-toc-link"));
  var observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) {
          return;
        }
        tocLinks.forEach(function (link) { link.classList.remove("is-active"); });
        var active = toc.querySelector(".post-toc-link[href='#" + entry.target.id + "']");
        if (active) {
          active.classList.add("is-active");
        }
      });
    },
    { rootMargin: "-15% 0px -70% 0px", threshold: [0, 1] }
  );

  tocItems.forEach(function (item) {
    var target = document.getElementById(item.id);
    if (target) {
      observer.observe(target);
    }
  });
})();
