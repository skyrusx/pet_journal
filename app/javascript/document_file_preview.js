const documentFileState = new WeakMap();

function formatFileSize(bytes) {
  if (!Number.isFinite(bytes) || bytes <= 0) return "0 Б";

  const units = ["Б", "КБ", "МБ", "ГБ"];
  const exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  const value = bytes / (1024 ** exponent);
  const digits = exponent === 0 || value >= 10 ? 0 : 1;

  return `${value.toFixed(digits)} ${units[exponent]}`;
}

function fileSignature(file) {
  return [file.name, file.size, file.lastModified, file.type].join("::");
}

function revokePreviewUrls(input) {
  const state = documentFileState.get(input);
  state?.previewUrls?.forEach((url) => URL.revokeObjectURL(url));
  if (state) state.previewUrls = [];
}

function assignFiles(input, files) {
  const transfer = new DataTransfer();
  files.forEach((file) => transfer.items.add(file));
  input.files = transfer.files;
}

function fileKind(file) {
  if (file.type.startsWith("image/")) return "image";
  if (file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf")) return "pdf";
  return "file";
}

function fallbackIcon(kind) {
  if (kind === "pdf") return "PDF";
  return "FILE";
}

function renderDocumentFiles(input) {
  const control = input.closest("[data-document-file-control]");
  const previewList = control?.querySelector("[data-document-file-previews]");
  if (!control || !previewList) return;

  const state = documentFileState.get(input) || { files: [], previewUrls: [] };
  revokePreviewUrls(input);
  state.previewUrls = [];
  previewList.replaceChildren();

  state.files.forEach((file, index) => {
    const row = document.createElement("div");
    row.className = "pj-document-selected-file";

    const preview = document.createElement("span");
    preview.className = "pj-document-selected-file__preview";

    const kind = fileKind(file);
    if (kind === "image") {
      const image = document.createElement("img");
      const previewUrl = URL.createObjectURL(file);
      state.previewUrls.push(previewUrl);
      image.src = previewUrl;
      image.alt = "";
      preview.appendChild(image);
    } else {
      preview.classList.add(`is-${kind}`);
      preview.textContent = fallbackIcon(kind);
    }

    const copy = document.createElement("span");
    copy.className = "pj-document-selected-file__copy";

    const name = document.createElement("strong");
    name.textContent = file.name;

    const meta = document.createElement("small");
    const typeLabel = kind === "image" ? "Изображение" : kind === "pdf" ? "PDF" : "Файл";
    meta.textContent = `${typeLabel} · ${formatFileSize(file.size)}`;

    copy.append(name, meta);

    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "pj-document-selected-file__remove";
    remove.setAttribute("aria-label", `Убрать ${file.name}`);
    remove.title = "Убрать файл";
    remove.textContent = "×";
    remove.addEventListener("click", () => removeDocumentFile(input, index));

    row.append(preview, copy, remove);
    previewList.appendChild(row);
  });

  previewList.hidden = state.files.length === 0;
  control.classList.toggle("has-selected-files", state.files.length > 0);
  documentFileState.set(input, state);
}

function addDocumentFiles(input, incomingFiles) {
  const state = documentFileState.get(input) || { files: [], previewUrls: [] };
  const known = new Set(state.files.map(fileSignature));

  Array.from(incomingFiles || []).forEach((file) => {
    const signature = fileSignature(file);
    if (known.has(signature)) return;

    known.add(signature);
    state.files.push(file);
  });

  documentFileState.set(input, state);
  assignFiles(input, state.files);
  renderDocumentFiles(input);
}

function removeDocumentFile(input, index) {
  const state = documentFileState.get(input);
  if (!state) return;

  state.files.splice(index, 1);
  assignFiles(input, state.files);
  renderDocumentFiles(input);
}

function initDocumentFilePreview() {
  document.querySelectorAll(".pj-document-dropzone__input").forEach((input) => {
    if (input.dataset.documentFilePreviewBound === "true") return;

    const control = input.closest("[data-document-file-control]");
    const dropzone = control?.querySelector("[data-document-file-dropzone]");
    if (!control || !dropzone) return;

    input.dataset.documentFilePreviewBound = "true";
    documentFileState.set(input, { files: Array.from(input.files || []), previewUrls: [] });

    input.addEventListener("change", () => {
      const newlyChosen = Array.from(input.files || []);
      const state = documentFileState.get(input) || { files: [], previewUrls: [] };

      // The browser replaces FileList on every picker interaction. Keep the
      // files already selected during this form session and append the new ones.
      input.value = "";
      assignFiles(input, state.files);
      addDocumentFiles(input, newlyChosen);
    });

    ["dragenter", "dragover"].forEach((eventName) => {
      dropzone.addEventListener(eventName, (event) => {
        event.preventDefault();
        event.stopPropagation();
        dropzone.classList.add("is-dragging");
      });
    });

    ["dragleave", "drop"].forEach((eventName) => {
      dropzone.addEventListener(eventName, (event) => {
        event.preventDefault();
        event.stopPropagation();
        dropzone.classList.remove("is-dragging");
      });
    });

    dropzone.addEventListener("drop", (event) => {
      addDocumentFiles(input, event.dataTransfer?.files);
    });

    renderDocumentFiles(input);
  });
}

function cleanupDocumentFilePreviews() {
  document.querySelectorAll(".pj-document-dropzone__input").forEach(revokePreviewUrls);
}

document.addEventListener("DOMContentLoaded", initDocumentFilePreview);
document.addEventListener("turbo:load", initDocumentFilePreview);
document.addEventListener("turbo:render", initDocumentFilePreview);
document.addEventListener("turbo:before-cache", cleanupDocumentFilePreviews);
