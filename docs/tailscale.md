# Tailscale

Some notes about the tailsale setup.

- The tailnet named 'the-technat.github' was created when I signedup using Github 
- The domain for the tailnet is 'crocodile-bee.ts.net' and was generated manually, can't be changed later on
- most features tailscale provides are enabled, including MagicDNS, HTTPS 
- new devices must be approved manually, thus automatic joining via key always needs pre-approved keys

The ACL is synced from this repo to the tailnet via an API key. The API key expires every 90 days, so it needs to be updated, but it's generic and can thus be used by other actions as well.