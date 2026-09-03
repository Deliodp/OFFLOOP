async function settings() {
  try {
    return await browser.runtime.sendNativeMessage(
      "com.yourcompany.SocialControl",
      {type:"settings"}
    );
  } catch (_) {
    return {reels:true,shorts:true,ads:false};
  }
}

async function syncRules() {
  const s = await settings();
  try {
    const enabled = await browser.declarativeNetRequest.getEnabledRulesets();
    const hasRules = enabled.includes("youtube_ads");

    if (s.ads && !hasRules) {
      await browser.declarativeNetRequest.updateEnabledRulesets({enableRulesetIds:["youtube_ads"]});
    } else if (!s.ads && hasRules) {
      await browser.declarativeNetRequest.updateEnabledRulesets({disableRulesetIds:["youtube_ads"]});
    }
  } catch (_) {}
  return s;
}

browser.runtime.onMessage.addListener(message => {
  if (message?.type === "settings") return syncRules();
});

syncRules();
