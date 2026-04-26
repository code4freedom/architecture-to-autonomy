(function () {
  var contentRoot = document.querySelector("article:not(.related-card)");
  var usesArticleLayout = true;
  if (!contentRoot) {
    contentRoot = document.querySelector(".main-wrap");
    usesArticleLayout = false;
  }
  if (!contentRoot) {
    return;
  }

  function countWords(text) {
    var tokens = text.trim().match(/[A-Za-z0-9][A-Za-z0-9'-]*/g);
    return tokens ? tokens.length : 0;
  }

  function toIsoDurationMinutes(minutes) {
    return "PT" + String(Math.max(1, minutes)) + "M";
  }

  function updateReadTime() {
    var articleText = contentRoot.textContent || "";
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
  }

  function inferImageDimensions(src) {
    var value = String(src || "");
    var linkedInMatch = value.match(/shrink_(\d{3,5})_(\d{3,5})/i);
    if (linkedInMatch) {
      return {
        width: parseInt(linkedInMatch[1], 10),
        height: parseInt(linkedInMatch[2], 10)
      };
    }

    var genericMatch = value.match(/(\d{3,5})x(\d{3,5})/i);
    if (genericMatch) {
      return {
        width: parseInt(genericMatch[1], 10),
        height: parseInt(genericMatch[2], 10)
      };
    }

    if (/a2a-logo/i.test(value)) {
      return { width: 32, height: 32 };
    }

    return { width: 1200, height: 675 };
  }

  function optimizeImages() {
    var images = Array.prototype.slice.call(contentRoot.querySelectorAll("img"));
    if (!images.length) {
      return;
    }

    images.forEach(function (img) {
      if (!img.hasAttribute("loading")) {
        img.setAttribute("loading", "lazy");
      }
      if (!img.hasAttribute("decoding")) {
        img.setAttribute("decoding", "async");
      }

      var hasWidth = img.hasAttribute("width");
      var hasHeight = img.hasAttribute("height");
      if (!hasWidth || !hasHeight) {
        var dims = inferImageDimensions(img.getAttribute("src"));
        if (!hasWidth && dims.width > 0) {
          img.setAttribute("width", String(dims.width));
        }
        if (!hasHeight && dims.height > 0) {
          img.setAttribute("height", String(dims.height));
        }
      }
    });
  }

  function normalizeTag(value) {
    return String(value || "").trim().toLowerCase();
  }

  function escapeHtml(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function parseDate(value) {
    var stamp = Date.parse(value || 0);
    return Number.isNaN(stamp) ? 0 : stamp;
  }

  function currentSlug() {
    var pathname = String(window.location.pathname || "");
    var filename = pathname.split("/").pop() || "";
    return filename.replace(/\.html$/i, "").toLowerCase();
  }

  function loadPostsData() {
    return new Promise(function (resolve) {
      if (Array.isArray(window.ARCH_TO_AUTONOMY_POSTS)) {
        resolve(window.ARCH_TO_AUTONOMY_POSTS);
        return;
      }

      var existing = document.querySelector("script[data-a2a-posts='1']");
      if (existing) {
        if (Array.isArray(window.ARCH_TO_AUTONOMY_POSTS)) {
          resolve(window.ARCH_TO_AUTONOMY_POSTS);
          return;
        }

        var settled = false;
        existing.addEventListener("load", function () {
          settled = true;
          resolve(Array.isArray(window.ARCH_TO_AUTONOMY_POSTS) ? window.ARCH_TO_AUTONOMY_POSTS : []);
        });
        existing.addEventListener("error", function () {
          settled = true;
          resolve([]);
        });
        window.setTimeout(function () {
          if (!settled) {
            resolve(Array.isArray(window.ARCH_TO_AUTONOMY_POSTS) ? window.ARCH_TO_AUTONOMY_POSTS : []);
          }
        }, 1500);
        return;
      }

      var script = document.createElement("script");
      script.src = "../assets/posts-data.js";
      script.async = true;
      script.setAttribute("data-a2a-posts", "1");
      script.onload = function () {
        resolve(Array.isArray(window.ARCH_TO_AUTONOMY_POSTS) ? window.ARCH_TO_AUTONOMY_POSTS : []);
      };
      script.onerror = function () {
        resolve([]);
      };
      document.head.appendChild(script);
    });
  }

  function buildRelatedPosts(posts) {
    var slug = currentSlug();
    if (!slug || !Array.isArray(posts) || !posts.length) {
      return;
    }

    var current = null;
    for (var i = 0; i < posts.length; i += 1) {
      if (normalizeTag(posts[i].slug) === normalizeTag(slug)) {
        current = posts[i];
        break;
      }
    }
    if (!current) {
      return;
    }

    var currentTags = Object.create(null);
    (current.tags || []).forEach(function (tag) {
      var key = normalizeTag(tag);
      if (key) {
        currentTags[key] = true;
      }
    });

    var scored = posts.filter(function (post) {
      return normalizeTag(post.slug) !== normalizeTag(current.slug);
    }).map(function (post) {
      var overlap = 0;
      (post.tags || []).forEach(function (tag) {
        if (currentTags[normalizeTag(tag)]) {
          overlap += 1;
        }
      });
      return {
        post: post,
        overlap: overlap,
        publishedAt: parseDate(post.published)
      };
    });

    scored.sort(function (a, b) {
      if (b.overlap !== a.overlap) {
        return b.overlap - a.overlap;
      }
      return b.publishedAt - a.publishedAt;
    });

    var selected = scored.filter(function (item) { return item.overlap > 0; }).slice(0, 3);
    if (selected.length < 3) {
      var used = Object.create(null);
      selected.forEach(function (item) {
        used[normalizeTag(item.post.slug)] = true;
      });

      scored.forEach(function (item) {
        var key = normalizeTag(item.post.slug);
        if (!used[key] && selected.length < 3) {
          used[key] = true;
          selected.push(item);
        }
      });
    }

    if (!selected.length) {
      return;
    }

    var host = usesArticleLayout ? contentRoot.parentNode : contentRoot;
    if (!host || document.querySelector(".related-posts")) {
      return;
    }

    var section = document.createElement("section");
    section.className = "related-posts";
    section.innerHTML = [
      "<div class=\"related-head\">",
      "<h3>Related posts</h3>",
      "<p>Continue with adjacent thinking threads.</p>",
      "</div>",
      "<div class=\"related-grid\">",
      selected.map(function (item) {
        var post = item.post;
        var dateLabel = post.publishedLabel ? ("Published " + post.publishedLabel) : "";
        return [
          "<article class=\"related-card\">",
          "<h4><a href=\"" + escapeHtml(post.url || "#") + "\">" + escapeHtml(post.title || "Untitled post") + "</a></h4>",
          "<p class=\"related-excerpt\">" + escapeHtml(post.excerpt || "") + "</p>",
          "<p class=\"related-meta\">" + escapeHtml(dateLabel) + "</p>",
          "<a class=\"related-link\" href=\"" + escapeHtml(post.url || "#") + "\">Open post</a>",
          "</article>"
        ].join("");
      }).join(""),
      "</div>"
    ].join("");

    var navBlock = host.querySelector(".post-end-nav, .bottom-nav");
    if (navBlock) {
      host.insertBefore(section, navBlock);
    } else if (usesArticleLayout && contentRoot.nextSibling) {
      host.insertBefore(section, contentRoot.nextSibling);
    } else {
      host.appendChild(section);
    }
  }

  updateReadTime();
  optimizeImages();
  loadPostsData().then(buildRelatedPosts);

  // Reading progress bar — pinned at the very top of the page, fills as the
  // reader scrolls through the article body. Honors prefers-reduced-motion
  // by skipping the smooth-fill transition.
  function setupReadingProgress() {
    if (!contentRoot) return;
    var bar = document.createElement("div");
    bar.className = "reading-progress";
    bar.setAttribute("role", "progressbar");
    bar.setAttribute("aria-label", "Reading progress");
    bar.setAttribute("aria-valuemin", "0");
    bar.setAttribute("aria-valuemax", "100");
    var fill = document.createElement("div");
    fill.className = "reading-progress-fill";
    bar.appendChild(fill);
    document.body.insertBefore(bar, document.body.firstChild);

    var ticking = false;
    function update() {
      var rect = contentRoot.getBoundingClientRect();
      var viewportH = window.innerHeight || document.documentElement.clientHeight;
      var articleTop = rect.top + window.pageYOffset;
      var articleHeight = contentRoot.offsetHeight;
      var distance = articleHeight - viewportH;
      var scrolled = window.pageYOffset - articleTop;
      var pct = 0;
      if (distance > 0) {
        pct = Math.max(0, Math.min(1, scrolled / distance));
      } else if (scrolled >= 0) {
        pct = 1;
      }
      fill.style.transform = "scaleX(" + pct + ")";
      bar.setAttribute("aria-valuenow", String(Math.round(pct * 100)));
      ticking = false;
    }
    function onScroll() {
      if (!ticking) {
        window.requestAnimationFrame(update);
        ticking = true;
      }
    }
    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll, { passive: true });
    update();
  }
  setupReadingProgress();

  // TOC intentionally disabled across all posts.
})();
