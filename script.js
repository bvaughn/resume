const url = new URL(window.location.href);
if (url.searchParams.has("print")) {
  const downloadLink = document.querySelector(".download-link");
  downloadLink.style.display = "none";
}
