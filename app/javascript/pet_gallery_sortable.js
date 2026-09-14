function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content || "";
}

async function persistOrder(url, photoIds) {
  const response = await fetch(url, {
    method: "PATCH",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: JSON.stringify({ photo_ids: photoIds })
  });

  if (response.ok) return;

  let payload = {};
  try {
    payload = await response.json();
  } catch (_error) {
    payload = {};
  }

  throw new Error(payload.error || "Не удалось сохранить порядок фотографий.");
}

function animateLayout(list, draggedCard, placeholder, mutate) {
  const cards = [...list.querySelectorAll("[data-pet-gallery-card]")]
    .filter((item) => item !== draggedCard && item !== placeholder);
  const before = new Map(cards.map((item) => [item, item.getBoundingClientRect()]));

  mutate();

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  cards.forEach((item) => {
    const previous = before.get(item);
    const current = item.getBoundingClientRect();
    if (!previous) return;

    const deltaX = previous.left - current.left;
    const deltaY = previous.top - current.top;
    if (Math.abs(deltaX) < 1 && Math.abs(deltaY) < 1) return;

    item._petGalleryMoveAnimation?.cancel();
    item._petGalleryMoveAnimation = item.animate(
      [
        { transform: `translate3d(${deltaX}px, ${deltaY}px, 0)` },
        { transform: "translate3d(0, 0, 0)" }
      ],
      {
        duration: 340,
        easing: "cubic-bezier(.22, 1, .36, 1)"
      }
    );
  });
}

function nearestCard(list, draggedCard, clientX, clientY) {
  const directTarget = document.elementFromPoint(clientX, clientY)?.closest?.("[data-pet-gallery-card]");
  if (directTarget && directTarget !== draggedCard && directTarget.parentElement === list) return directTarget;

  const cards = [...list.querySelectorAll("[data-pet-gallery-card]")].filter((item) => item !== draggedCard);
  let best = null;
  let bestDistance = Number.POSITIVE_INFINITY;

  cards.forEach((item) => {
    const rect = item.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    const distance = Math.hypot(clientX - centerX, clientY - centerY);

    if (distance < bestDistance) {
      best = item;
      bestDistance = distance;
    }
  });

  return best;
}

function installSmoothGallerySorting() {
  if (document.documentElement.dataset.petGallerySmoothSorting === "true") return;
  document.documentElement.dataset.petGallerySmoothSorting = "true";

  document.addEventListener("pointerdown", (event) => {
    const handle = event.target.closest?.("[data-pet-gallery-sort-handle]");
    if (!handle) return;
    if (event.pointerType === "mouse" && event.button !== 0) return;

    const card = handle.closest("[data-pet-gallery-card]");
    const list = card?.closest("[data-pet-gallery-sort-list]");
    const editor = card?.closest("[data-pet-gallery-editor]");
    if (!card || !list || !editor) return;

    event.preventDefault();
    event.stopPropagation();

    const status = editor.querySelector("[data-pet-gallery-status]");
    const initialOrder = [...list.querySelectorAll("[data-pet-gallery-card]")]
      .map((item) => item.dataset.photoId)
      .join(",");
    const startRect = card.getBoundingClientRect();
    const pointerOffsetX = event.clientX - startRect.left;
    const pointerOffsetY = event.clientY - startRect.top;

    const placeholder = document.createElement("div");
    placeholder.className = "pj-pet-gallery-card--placeholder";
    placeholder.setAttribute("aria-hidden", "true");
    placeholder.style.height = `${startRect.height}px`;

    list.insertBefore(placeholder, card);

    card.classList.add("is-dragging");
    card.style.width = `${startRect.width}px`;
    card.style.height = `${startRect.height}px`;
    card.style.left = `${startRect.left}px`;
    card.style.top = `${startRect.top}px`;
    document.body.classList.add("pj-pet-gallery-reordering");

    let animationFrame = null;
    let lastPointerX = event.clientX;
    let lastPointerY = event.clientY;

    const positionDraggedCard = () => {
      animationFrame = null;
      card.style.left = `${lastPointerX - pointerOffsetX}px`;
      card.style.top = `${lastPointerY - pointerOffsetY}px`;
    };

    const scheduleDraggedCardPosition = () => {
      if (animationFrame !== null) return;
      animationFrame = window.requestAnimationFrame(positionDraggedCard);
    };

    const movePlaceholder = (clientX, clientY) => {
      const target = nearestCard(list, card, clientX, clientY);
      if (!target) return;

      const rect = target.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const sameRow = clientY >= rect.top && clientY <= rect.bottom;
      const placeBefore = sameRow ? clientX < centerX : clientY < centerY;

      const orderedCards = [...list.querySelectorAll("[data-pet-gallery-card]")].filter((item) => item !== card);
      const targetIndex = orderedCards.indexOf(target);
      if (targetIndex < 0) return;

      const insertionIndex = targetIndex + (placeBefore ? 0 : 1);
      const layoutNodes = [...list.children].filter((node) => node !== card);
      const currentIndex = layoutNodes.indexOf(placeholder);
      if (currentIndex === insertionIndex) return;

      const reference = orderedCards[insertionIndex] || null;
      animateLayout(list, card, placeholder, () => list.insertBefore(placeholder, reference));
    };

    const autoScroll = (clientY) => {
      const edge = 72;
      const maxSpeed = 10;

      if (clientY < edge) {
        window.scrollBy(0, -Math.ceil(maxSpeed * (1 - clientY / edge)));
      } else if (clientY > window.innerHeight - edge) {
        const distance = window.innerHeight - clientY;
        window.scrollBy(0, Math.ceil(maxSpeed * (1 - distance / edge)));
      }
    };

    const move = (moveEvent) => {
      moveEvent.preventDefault();
      lastPointerX = moveEvent.clientX;
      lastPointerY = moveEvent.clientY;
      scheduleDraggedCardPosition();
      movePlaceholder(moveEvent.clientX, moveEvent.clientY);
      autoScroll(moveEvent.clientY);
    };

    const cleanup = () => {
      window.removeEventListener("pointermove", move, true);
      window.removeEventListener("pointerup", finish, true);
      window.removeEventListener("pointercancel", finish, true);
      if (animationFrame !== null) window.cancelAnimationFrame(animationFrame);
      document.body.classList.remove("pj-pet-gallery-reordering");
    };

    const finish = async (finishEvent) => {
      finishEvent?.preventDefault();
      cleanup();

      const floatingRect = card.getBoundingClientRect();
      const destinationRect = placeholder.getBoundingClientRect();
      placeholder.replaceWith(card);

      card.classList.remove("is-dragging");
      card.style.removeProperty("width");
      card.style.removeProperty("height");
      card.style.removeProperty("left");
      card.style.removeProperty("top");

      if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches && card.animate) {
        const deltaX = floatingRect.left - destinationRect.left;
        const deltaY = floatingRect.top - destinationRect.top;
        card.animate(
          [
            { transform: `translate3d(${deltaX}px, ${deltaY}px, 0) scale(1.015)` },
            { transform: "translate3d(0, 0, 0) scale(1)" }
          ],
          {
            duration: 320,
            easing: "cubic-bezier(.22, 1, .36, 1)"
          }
        );
      }

      const photoIds = [...list.querySelectorAll("[data-pet-gallery-card]")].map((item) => Number(item.dataset.photoId));
      if (photoIds.join(",") === initialOrder) return;

      if (status) status.textContent = "Сохраняем порядок…";
      try {
        await persistOrder(editor.dataset.reorderUrl, photoIds);
        if (status) status.textContent = "Порядок сохранён.";
      } catch (error) {
        if (status) status.textContent = error.message;
        window.setTimeout(() => window.location.reload(), 900);
      }
    };

    window.addEventListener("pointermove", move, { capture: true, passive: false });
    window.addEventListener("pointerup", finish, { capture: true, once: true });
    window.addEventListener("pointercancel", finish, { capture: true, once: true });
  }, true);
}

installSmoothGallerySorting();
