// Edge Function: 사용량 알림
// Webhook (Discord/Slack/Telegram)으로 알림 전송

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const WEBHOOK_URL = Deno.env.get("USAGE_ALERT_WEBHOOK_URL");
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN");
const TELEGRAM_CHAT_ID = Deno.env.get("TELEGRAM_CHAT_ID");

interface UsageAlert {
  alert_type: string;
  threshold_value: number;
  current_value: number;
  message: string;
}

Deno.serve(async (req: Request) => {
  try {
    // CORS 처리
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const alert: UsageAlert = await req.json();

    // 알림 메시지 포맷팅
    const emoji = alert.alert_type === "threshold_reached" ? "🚨" : "⚠️";
    const color = alert.alert_type === "threshold_reached" ? 0xff0000 : 0xffa500;
    const title =
      alert.alert_type === "threshold_reached"
        ? "서비스 한도 도달!"
        : "사용량 경고";

    const percentage = Math.round(
      (alert.current_value / alert.threshold_value) * 100
    );

    // Discord Webhook 형식
    const discordPayload = {
      embeds: [
        {
          title: `${emoji} Destiny.OS ${title}`,
          description: alert.message,
          color: color,
          fields: [
            {
              name: "현재 사용량",
              value: `${alert.current_value.toLocaleString()}회`,
              inline: true,
            },
            {
              name: "한도",
              value: `${alert.threshold_value.toLocaleString()}회`,
              inline: true,
            },
            {
              name: "사용률",
              value: `${percentage}%`,
              inline: true,
            },
          ],
          timestamp: new Date().toISOString(),
          footer: {
            text: "Destiny.OS Usage Monitor",
          },
        },
      ],
    };

    // Slack Webhook 형식
    const slackPayload = {
      blocks: [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: `${emoji} Destiny.OS ${title}`,
          },
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: alert.message,
          },
        },
        {
          type: "section",
          fields: [
            {
              type: "mrkdwn",
              text: `*현재 사용량:*\n${alert.current_value.toLocaleString()}회`,
            },
            {
              type: "mrkdwn",
              text: `*한도:*\n${alert.threshold_value.toLocaleString()}회`,
            },
          ],
        },
      ],
    };

    // Telegram 메시지 형식
    const telegramMessage = `${emoji} <b>Destiny.OS ${title}</b>

${alert.message}

📊 <b>현재 사용량:</b> ${alert.current_value.toLocaleString()}회
📈 <b>한도:</b> ${alert.threshold_value.toLocaleString()}회
⚡ <b>사용률:</b> ${percentage}%

🕐 ${new Date().toLocaleString("ko-KR", { timeZone: "Asia/Seoul" })}`;

    // 1. Telegram 우선 전송 (설정된 경우)
    if (TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) {
      const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
      const telegramPayload = {
        chat_id: TELEGRAM_CHAT_ID,
        text: telegramMessage,
        parse_mode: "HTML",
      };

      const response = await fetch(telegramUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(telegramPayload),
      });

      if (!response.ok) {
        console.error("Telegram failed:", await response.text());
      } else {
        console.log("Telegram alert sent successfully");
      }
    }

    // 2. Discord/Slack Webhook (설정된 경우)
    if (WEBHOOK_URL) {
      const isDiscord = WEBHOOK_URL.includes("discord.com");
      const payload = isDiscord ? discordPayload : slackPayload;

      const response = await fetch(WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        console.error("Webhook failed:", await response.text());
      }
    }

    // 결과 반환
    const configured = !!(TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID) || !!WEBHOOK_URL;
    if (configured) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "Alert sent successfully",
          channels: {
            telegram: !!(TELEGRAM_BOT_TOKEN && TELEGRAM_CHAT_ID),
            webhook: !!WEBHOOK_URL,
          },
        }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    } else {
      // 설정된 알림 채널이 없으면 콘솔에만 로그
      console.log("Usage Alert:", alert);
      return new Response(
        JSON.stringify({
          success: true,
          message: "Alert logged (no notification channel configured)",
          alert: alert,
        }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    }
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
