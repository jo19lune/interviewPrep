document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('secure-form');
    const cguCheckbox = document.getElementById('cgu-consent');
    const cguError = document.getElementById('cgu-error');
    const rememberMeCheckbox = document.getElementById('remember-me');

    form.addEventListener('submit', function(event) {
        // Prévenir la soumission par défaut pour validation côté client
        event.preventDefault();

        // 1. VALIDATION RGPD / CGU
        if (!cguCheckbox.checked) {
            // Affichage de l'erreur
            cguError.hidden = false;
            // Mise à jour de l'attribut ARIA pour l'accessibilité
            cguCheckbox.setAttribute('aria-invalid', 'true');
            // Focus sur la checkbox pour que le lecteur d'écran annonce l'erreur via aria-describedby
            cguCheckbox.focus();
            return; // Bloque la soumission
        } else {
            // Réinitialisation de l'état d'erreur
            cguError.hidden = true;
            cguCheckbox.setAttribute('aria-invalid', 'false');
        }

        // 2. GESTION "SE SOUVENIR DE MOI" (Théorie & Simulation)
        const rememberMe = rememberMeCheckbox.checked;
        
        /**
         * SÉCURITÉ & GESTION DE SESSION :
         * 
         * Si `rememberMe` est vrai, le backend doit être configuré pour :
         * 
         * a) Approche Cookies (Recommandé) :
         *    Émettre un cookie d'authentification (ou un Refresh Token) avec les attributs suivants :
         *    - HttpOnly : Empêche l'accès au cookie via JavaScript (ex: document.cookie), bloquant ainsi les attaques XSS.
         *    - Secure : Garantit que le cookie n'est envoyé que sur des connexions HTTPS chiffrées.
         *    - SameSite=Strict (ou Lax) : Protège contre les attaques CSRF (Cross-Site Request Forgery) en n'envoyant le cookie que pour les requêtes provenant du même domaine.
         *    - Max-Age / Expires : Définit une durée de vie prolongée (ex: 30 jours) si l'utilisateur a coché la case.
         * 
         * b) Approche JWT en LocalStorage (Moins recommandé si vulnérabilité XSS) :
         *    Stocker un JWT de longue durée. Cela nécessite une hygiène stricte contre les XSS (échappement de toutes les entrées utilisateurs, CSP robuste) car le LocalStorage est accessible en JS.
         *    Dans une architecture robuste, on stocke un access token court en mémoire et un refresh token en cookie HttpOnly.
         * 
         * PROTECTION CSRF SUPPLÉMENTAIRE :
         * En plus de `SameSite`, inclure un jeton anti-CSRF dans l'en-tête de la requête ou utiliser le pattern Double Submit Cookie.
         */

        // Simulation d'un payload sécurisé envoyé au backend
        const payload = {
            email: form.email.value,
            password: form.password.value, // Le backend devra hasher ce mdp avec Argon2 ou bcrypt
            remember_me: rememberMe,
            cgu_accepted: cguCheckbox.checked
        };

        console.log("Validation réussie. Payload prêt pour le backend (sur HTTPS) :", payload);
        alert("Formulaire validé avec succès ! (Voir console pour les détails de sécurité)");
        
        // Form submission logic here (e.g., fetch API call)
        // form.submit(); // Uniquement si fallback non-AJAX
    });

    // Amélioration de l'UX : masquer le message d'erreur dès que l'utilisateur coche la case
    cguCheckbox.addEventListener('change', () => {
        if (cguCheckbox.checked) {
            cguError.hidden = true;
            cguCheckbox.setAttribute('aria-invalid', 'false');
        }
    });
});
