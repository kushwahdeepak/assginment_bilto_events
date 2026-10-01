(function () {
  var page = document.querySelector(".events-page");
  if (!page) return;

  var publishableKey = page.dataset.clerkPublishableKey;
  var authActions = document.getElementById("clerk-auth-actions");
  var userButton = document.getElementById("clerk-user-button");
  var accountStatus = document.getElementById("clerk-account-status");
  var status = document.getElementById("clerk-status");
  var mockUser = document.cookie.indexOf("mock_clerk_user_id=") !== -1;

  if (mockUser) {
    enableMockVoting();
    return;
  }

  if (!publishableKey) return;

  if (window.Clerk) {
    startClerk();
    return;
  }

  var clerkScript = document.createElement("script");
  clerkScript.src = "https://cdn.jsdelivr.net/npm/@clerk/clerk-js@5/dist/clerk.browser.js";
  clerkScript.dataset.clerkPublishableKey = publishableKey;
  clerkScript.crossOrigin = "anonymous";
  clerkScript.onload = startClerk;
  clerkScript.onerror = function () {
    status.textContent = "Clerk could not be loaded.";
  };
  document.head.appendChild(clerkScript);

  function startClerk() {
    window.Clerk.load().then(function () {
      window.Clerk.addListener(updateAccount);

      document.getElementById("clerk-sign-in").addEventListener("click", function () {
        window.Clerk.openSignIn();
      });
      document.getElementById("clerk-sign-up").addEventListener("click", function () {
        window.Clerk.openSignUp();
      });

      document.querySelectorAll("[data-vote-type]").forEach(function (button) {
        button.addEventListener("click", function () {
          submitVote(button);
        });
      });
    }).catch(function () {
      status.textContent = "Clerk could not be loaded.";
    });
  }

  function updateAccount(data) {
    var user = data.user;
    authActions.hidden = Boolean(user);
    userButton.hidden = !user;
    accountStatus.textContent = user ? "Signed in" : "Not signed in";

    document.querySelectorAll("[data-vote-type]").forEach(function (button) {
      button.disabled = !user;
    });

    if (user && !userButton.dataset.mounted) {
      window.Clerk.mountUserButton(userButton);
      userButton.dataset.mounted = "true";
    }
  }

  function submitVote(button) {
    button.disabled = true;
    status.textContent = "Submitting vote…";

    var request = mockUser
      ? Promise.resolve(null)
      : window.Clerk.session.getToken();

    request.then(function (token) {
      var headers = {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      };
      if (token) headers.Authorization = "Bearer " + token;
      if (mockUser) headers["X-Mock-User-Id"] = "user_mock123";

      return fetch("/events/" + button.dataset.eventId + "/votes", {
        method: "POST",
        headers: headers,
        body: JSON.stringify({ type: button.dataset.voteType })
      });
    }).then(function (response) {
      if (response.ok) {
        window.location.reload();
        return;
      }

      return response.json().then(function (result) {
        var message = result.error || (result.errors || []).join(", ") || "Vote failed.";
        throw new Error(message);
      });
    }).catch(function (error) {
      status.textContent = error.message;
      button.disabled = false;
    });
  }

  function enableMockVoting() {
    accountStatus.textContent = "Signed in";
    document.getElementById("mock-sign-out").hidden = false;
    document.querySelectorAll("[data-vote-type]").forEach(function (button) {
      button.disabled = false;
      button.addEventListener("click", function () {
        submitVote(button);
      });
    });
  }
})();