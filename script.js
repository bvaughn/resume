function syncContactInfo(dataTestName) {
  const headerElement = document.querySelector(
    `[data-test-location="header"][data-test-name="${dataTestName}"]`
  );
  const sidebarElement = document.querySelector(
    `[data-test-location="sidebar"][data-test-name="${dataTestName}"]`
  );

  if (headerElement && sidebarElement) {
    headerElement.innerHTML = sidebarElement.innerHTML;
  }
}

syncContactInfo("contact-location");
syncContactInfo("contact-phone");
syncContactInfo("contact-email");
syncContactInfo("contact-github");
syncContactInfo("contact-pdf");

const url = new URL(window.location.href);
if (url.searchParams.has("print")) {
  document
    .querySelectorAll('[data-test-name="contact-pdf"]')
    .forEach((element) => (element.style.display = "none"));
}
