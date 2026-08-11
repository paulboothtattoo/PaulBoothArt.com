/**
 * Contact form client for paulboothart.com and paulbooth.ai.
 *
 * Binds to any <form data-pb-contact> and handles: fetching a proof-of-work
 * challenge, solving it, posting the submission, and reporting status.
 *
 * Required markup:
 *   <form data-pb-contact data-site="art|ai" data-endpoint="https://…">
 * Input `name` attributes must match the field names in the service's
 * lib/forms.js. Two hidden inputs are managed here and need no markup:
 * `website` (honeypot) and `startedAt` (fill-time check).
 *
 * This file is deployed to both sites. Edit it in the paulbooth-forms repo and
 * copy it out, so the two copies do not drift.
 */
(() => {
  "use strict";

  // The deployed Railway service. This is the one line to change if the
  // service URL ever moves; a form may override it with data-endpoint.
  const ENDPOINT = "https://paulbooth-forms-production.up.railway.app";

  const toHex = (buffer) =>
    Array.from(new Uint8Array(buffer))
      .map((byte) => byte.toString(16).padStart(2, "0"))
      .join("");

  const sha256 = async (value) =>
    toHex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)));

  /**
   * Brute-force the challenge: find n where sha256(salt + n) === challenge.
   *
   * Yields to the event loop periodically so the page stays responsive while
   * solving — this takes a fraction of a second, but it should never feel like
   * the tab has locked up.
   */
  async function solve({ challenge, salt, maxnumber }, onProgress) {
    for (let number = 0; number <= maxnumber; number += 1) {
      if ((await sha256(salt + number)) === challenge) return number;

      if (number % 1000 === 0) {
        onProgress?.(number / maxnumber);
        await new Promise((resolve) => setTimeout(resolve, 0));
      }
    }
    throw new Error("unsolvable");
  }

  function statusElement(form) {
    let element = form.querySelector("[data-pb-status]");
    if (!element) {
      element = document.createElement("p");
      element.setAttribute("data-pb-status", "");
      element.setAttribute("role", "status");
      element.setAttribute("aria-live", "polite");
      form.appendChild(element);
    }
    return element;
  }

  function setStatus(form, state, message) {
    const element = statusElement(form);
    element.dataset.pbStatus = state;
    element.textContent = message;
  }

  function bind(form) {
    if (form.dataset.pbContactReady === "true") return;
    form.dataset.pbContactReady = "true";

    const endpoint = (form.dataset.endpoint || ENDPOINT).replace(/\/$/, "");
    const site = form.dataset.site;
    if (!endpoint || !site) {
      console.error("[pb-contact] form is missing data-site");
      return;
    }

    // Honeypot. Positioned off-screen by CSS rather than hidden with
    // `display:none`, which naive bots know to skip.
    const honeypot = document.createElement("input");
    honeypot.type = "text";
    honeypot.name = "website";
    honeypot.className = "pb-honeypot";
    honeypot.tabIndex = -1;
    honeypot.autocomplete = "off";
    honeypot.setAttribute("aria-hidden", "true");
    form.appendChild(honeypot);

    const startedAt = document.createElement("input");
    startedAt.type = "hidden";
    startedAt.name = "startedAt";
    startedAt.value = String(Date.now());
    form.appendChild(startedAt);

    const button = form.querySelector('button[type="submit"], button:not([type])');
    const buttonLabel = button?.innerHTML;

    form.addEventListener("submit", async (event) => {
      event.preventDefault();

      if (form.dataset.pbSubmitting === "true") return;
      if (!form.reportValidity()) return;

      form.dataset.pbSubmitting = "true";
      if (button) {
        button.disabled = true;
        button.innerHTML = "Verifying…";
      }
      setStatus(form, "working", "Running a quick verification check…");

      try {
        const challengeResponse = await fetch(`${endpoint}/api/challenge`, {
          method: "GET",
          mode: "cors",
        });
        if (!challengeResponse.ok) throw new Error("challenge-failed");
        const challenge = await challengeResponse.json();

        const number = await solve(challenge, (progress) => {
          if (button) button.innerHTML = `Verifying… ${Math.round(progress * 100)}%`;
        });

        const pow = btoa(
          JSON.stringify({
            algorithm: challenge.algorithm,
            challenge: challenge.challenge,
            salt: challenge.salt,
            number,
            signature: challenge.signature,
          }),
        );

        if (button) button.innerHTML = "Sending…";
        setStatus(form, "working", "Sending your inquiry…");

        const payload = new FormData(form);
        payload.set("pow", pow);

        const response = await fetch(`${endpoint}/api/contact/${site}`, {
          method: "POST",
          mode: "cors",
          body: payload,
        });
        const result = await response.json().catch(() => ({}));

        if (!response.ok) {
          setStatus(form, "error", result.error || "Something went wrong. Please try again.");
          return;
        }

        form.reset();
        startedAt.value = String(Date.now());
        setStatus(
          form,
          "success",
          "Your inquiry has been sent. You will receive a reply at the email address you provided.",
        );
      } catch (error) {
        console.error("[pb-contact]", error);
        setStatus(
          form,
          "error",
          "We could not reach the mail service. Please email lastritestattoo@gmail.com directly.",
        );
      } finally {
        form.dataset.pbSubmitting = "false";
        if (button) {
          button.disabled = false;
          button.innerHTML = buttonLabel;
        }
      }
    });
  }

  const bindAll = () => document.querySelectorAll("form[data-pb-contact]").forEach(bind);

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bindAll, { once: true });
  } else {
    bindAll();
  }

  // The art site injects its form after load, so re-scan once things settle.
  window.addEventListener("load", bindAll, { once: true });
  setTimeout(bindAll, 600);
})();
