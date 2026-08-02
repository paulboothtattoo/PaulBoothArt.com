(() => {
  "use strict";

  const protectedSelector = [
    "img",
    ".project-card",
    ".realm-card",
    ".machine-card",
    ".motion-screen",
    ".about-photo-frame",
    ".dialog-visual",
    ".video-card",
    ".fixed-site-background",
    ".statement-panel"
  ].join(",");

  const notice = document.createElement("div");
  notice.className = "pb-image-protection-notice";
  notice.textContent = "Artwork protected © Paul Booth — unauthorized copying is prohibited";
  notice.setAttribute("role", "status");
  notice.setAttribute("aria-live", "polite");
  document.body.appendChild(notice);

  let noticeTimer;
  const showNotice = () => {
    notice.classList.add("is-visible");
    window.clearTimeout(noticeTimer);
    noticeTimer = window.setTimeout(() => notice.classList.remove("is-visible"), 1800);
  };

  document.addEventListener("contextmenu", (event) => {
    if (event.target.closest(protectedSelector)) {
      event.preventDefault();
      showNotice();
    }
  }, true);

  document.addEventListener("dragstart", (event) => {
    if (event.target.closest(protectedSelector)) {
      event.preventDefault();
    }
  }, true);

  document.addEventListener("selectstart", (event) => {
    if (event.target.closest(protectedSelector)) {
      event.preventDefault();
    }
  }, true);

  document.addEventListener("copy", (event) => {
    const selection = window.getSelection();
    const anchor = selection && selection.anchorNode;
    const element = anchor && (anchor.nodeType === Node.ELEMENT_NODE ? anchor : anchor.parentElement);
    if (element && element.closest(protectedSelector)) {
      event.preventDefault();
      showNotice();
    }
  }, true);

  document.addEventListener("keydown", (event) => {
    const key = event.key.toLowerCase();
    const blocked = (event.ctrlKey || event.metaKey) && ["s", "u", "p"].includes(key);
    if (blocked) {
      event.preventDefault();
      showNotice();
    }
  }, true);

  const protectImage = (image) => {
    image.draggable = false;
    image.setAttribute("draggable", "false");
    image.setAttribute("data-protected-image", "true");
  };

  document.querySelectorAll("img").forEach(protectImage);

  const observer = new MutationObserver((records) => {
    records.forEach((record) => {
      record.addedNodes.forEach((node) => {
        if (!(node instanceof Element)) return;
        if (node.matches("img")) protectImage(node);
        node.querySelectorAll?.("img").forEach(protectImage);
      });
    });
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
