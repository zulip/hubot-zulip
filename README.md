# Zulip adapter for Hubot

Follow the [Getting Started with Hubot](https://hubot.github.com/docs/) page to create your Hubot.

In your Hubot's directory, run:

	npm install --save hubot-zulip

On your [Zulip settings page](https://zulip.com/#settings), create a bot account. Note its email and API key; you will use them on the next step.

The bot account email address and API key are passed to Hubot via environment variables `HUBOT_ZULIP_BOT` and `HUBOT_ZULIP_API_KEY`.

By default, the bot will listen on all public streams. If you set 
`HUBOT_ZULIP_ONLY_SUBSCRIBED_STREAMS`, it will only listen on the
streams that the bot is subscribed to.

To run Hubot locally, use:

	HUBOT_ZULIP_BOT=hubot-bot@example.com HUBOT_ZULIP_API_KEY=your_key bin/hubot -a zulip

To run Hubot with a self-hosted version of Zulip, use:

	HUBOT_ZULIP_SITE=https://zulip.example.com HUBOT_ZULIP_BOT=hubot-bot@example.com HUBOT_ZULIP_API_KEY=your_key bin/hubot -a zulip

To run Hubot on Heroku, edit `Procfile` to change the `-a` option to `-a zulip`. Use the following commands to set the environment variables:

	heroku config:add HUBOT_ZULIP_SITE=https://example.zulipchat.com/api
	heroku config:add HUBOT_ZULIP_API_KEY=your_key
	heroku config:add HUBOT_ZULIP_BOT=hubot-bot@example.com
