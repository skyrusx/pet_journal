function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content || "";
}

const TOUCH_HOLD_MS = 260;
const TOUCH_MOVE_TOLERANCE = 10;

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

function startDrag(handle, clientX, clientY) {
  const card = handle.closest("[data-pet-gallery-card]");
  const list = card?.closest("[data-pet-gallery-sort-list]");
  const editor = card?.closest("[data-pet-gallery-editor]");
  if (!card || !list || !editor) return null;

  const status = editor.querySelector("[data-pet-gallery-status]");
  const initialOrder = [...list.querySelectorAll("[data-pet-gallery-card]")]
    .map((item) => item.dataset.photoId)
    .join(",");
  const startRect = card.getBoundingClientRect();
  const pointerOffsetX = clientX - startRect.left;
  const pointerOffsetY = clientY - startRect.top;

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
  let lastPointerX = clientX;
  let lastPointerY = clientY;

  const positionDraggedCard = () => {
    animationFrame = null;
    card.style.left = `${lastPointerX - pointerOffsetX}px`;
    card.style.top = `${lastPointerY - pointerOffsetY}px`;
  };

  const scheduleDraggedCardPosition = () => {
    if (animationFrame !== null) return;
    animationFrame = window.requestAnimationFrame(positionDraggedCard);
  };

  const movePlaceholder = (nextX, nextY) => {
    const target = nearestCard(list, card, nextX, nextY);
    if (!target) return;

    const rect = target.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    const sameRow = nextY >= rect.top && nextY <= rect.bottom;
    const placeBefore = sameRow ? nextX < centerX : nextY < centerY;

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

  const autoScroll = (nextY) => {
    const edge = 72;
    const maxSpeed = 10;

    if (nextY < edge) {
      window.scrollBy(0, -Math.ceil(maxSpeed * (1 - nextY / edge)));
    } else if (nextY > window.innerHeight - edge) {
      const distance = window.innerHeight - nextY;
      window.scrollBy(0, Math.ceil(maxSpeed * (1 - distance / edge)));
    }
  };

  const move = (nextX, nextY) => {
    lastPointerX = nextX;
    lastPointerY = nextY;
    scheduleDraggedCardPosition();
    movePlaceholder(nextX, nextY);
    autoScroll(nextY);
  };

  const resetFloatingCard = () => {
    card.classList.remove("is-dragging");
    card.style.removeProperty("width");
    card.style.removeProperty("height");
    card.style.removeProperty("left");
    card.style.removeProperty("top");
    document.body.classList.remove("pj-pet-gallery-reordering");
    if (animationFrame !== null) window.cancelAnimationFrame(animationFrame);
  };

  const finish = async () => {
    const floatingRect = card.getBoundingClientRect();
    const destinationRect = placeholder.getBoundingClientRect();
    placeholder.replaceWith(card);
    resetFloatingCard();

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

  const cancel = () => {
    resetFloatingCard();
    window.location.reload();
  };

  return { move, finish, cancel };
}

function installMouseAndPenSorting() {
  document.addEventListener("pointerdown", (event) => {
    if (event.pointerType === "touch") return;

    const handle = event.target.closest?.("[data-pet-gallery-sort-handle]");
    if (!handle) return;
    if (event.pointerType === "mouse" && event.button !== 0) return;

    const session = startDrag(handle, event.clientX, event.clientY);
    if (!session) return;

    event.preventDefault();
    event.stopPropagation();

    const move = (moveEvent) => {
      moveEvent.preventDefault();
      session.move(moveEvent.clientX, moveEvent.clientY);
    };

    const cleanup = () => {
      window.removeEventListener("pointermove", move, true);
      window.removeEventListener("pointerup", finish, true);
      window.removeEventListener("pointercancel", cancel, true);
    };

    const finish = (finishEvent) => {
      finishEvent.preventDefault();
      cleanup();
      session.finish();
    };

    const cancel = () => {
      cleanup();
      session.cancel();
    };

    window.addEventListener("pointermove", move, { capture: true, passive: false });
    window.addEventListener("pointerup", finish, { capture: true, once: true });
    window.addEventListener("pointercancel", cancel, { capture: true, once: true });
  }, true);
}

function installTouchSorting() {
  document.addEventListener("touchstart", (event) => {
    if (event.touches.length !== 1) return;

    const handle = event.target.closest?.("[data-pet-gallery-sort-handle]");
    if (!handle) return;

    const touch = event.changedTouches[0];
    const touchId = touch.identifier;
    const startX = touch.clientX;
    const startY = touch.clientY;
    let session = null;
    let cancelledForScroll = false;

    const findTouch = (touches) => [...touches].find((item) => item.identifier === touchId);

    const holdTimer = window.setTimeout(() => {
      if (cancelledForScroll) return;
      session = startDrag(handle, startX, startY);
      if (session && navigator.vibrate) navigator.vibrate(12);
    }, TOUCH_HOLD_MS);

    const cleanup = () => {
      window.clearTimeout(holdTimer);
      window.removeEventListener("touchmove", move, true);
      window.removeEventListener("touchend", finish, true);
      window.removeEventListener("touchcancel", cancel, true);
    };

    const move = (moveEvent) => {
      const current = findTouch(moveEvent.touches);
      if (!current) return;

      if (!session) {
        const distance = Math.hypot(current.clientX - startX, current.clientY - startY);
        if (distance > TOUCH_MOVE_TOLERANCE) {
          cancelledForScroll = true;
          cleanup();
        }
        return;
      }

      moveEvent.preventDefault();
      session.move(current.clientX, current.clientY);
    };

    const finish = (finishEvent) => {
      const endedTouch = findTouch(finishEvent.changedTouches);
      if (!endedTouch) return;

      cleanup();
      if (!session) return;

      finishEvent.preventDefault();
      session.finish();
    };

    const cancel = () => {
      cleanup();
      if (session) session.cancel();
    };

    window.addEventListener("touchmove", move, { capture: true, passive: false });
    window.addEventListener("touchend", finish, { capture: true, passive: false });
    window.addEventListener("touchcancel", cancel, { capture: true, passive: true });
  }, { capture: true, passive: true });
}

function installSmoothGallerySorting() {
  if (document.documentElement.dataset.petGallerySmoothSorting === "true") return;
  document.documentElement.dataset.petGallerySmoothSorting = "true";

  installMouseAndPenSorting();
  installTouchSorting();
}

installSmoothGallerySorting();
