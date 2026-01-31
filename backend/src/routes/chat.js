const tencentcloud = require('tencentcloud-sdk-nodejs');
const config = require('../config');

const HunyuanClient = tencentcloud.hunyuan.v20230901.Client;

function normalizeMessages(messages) {
  if (!Array.isArray(messages)) return [];
  return messages
    .filter((m) => m && typeof m.content === 'string')
    .map((m) => ({
      Role: m.role || 'user',
      Content: m.content,
    }));
}

function buildVisionMessage({ question, imageBase64, imageMime }) {
  const mime = imageMime || 'image/jpeg';
  const url = imageBase64.startsWith('data:')
    ? imageBase64
    : `data:${mime};base64,${imageBase64}`;
  return [
    {
      Role: 'user',
      Contents: [
        {
          Type: 'text',
          Text: question || '请描述图片内容，并用儿童易懂的方式解释。',
        },
        {
          Type: 'image_url',
          ImageUrl: { Url: url },
        },
      ],
    },
  ];
}

function routes(app, getClient) {
  app.post('/chat', async (req, res) => {
    const client = getClient();
    if (!client) {
      return res.status(503).json({
        error: 'ai_disabled',
        message: '未配置腾讯云密钥，AI 对话不可用。请设置 TENCENT_SECRET_ID / TENCENT_SECRET_KEY。',
      });
    }
    try {
      const {
        messages,
        model = 'hunyuan-turbos-latest',
        temperature = 0.6,
        topP = 1.0,
        stream = false,
        imageBase64,
        imageMime,
        question,
      } = req.body || {};

      if (stream) {
        return res.status(400).json({
          error: 'streaming_not_supported',
          message: 'Streaming is not enabled yet.',
        });
      }

      const isVision = typeof imageBase64 === 'string' && imageBase64.length > 0;
      const normalized = isVision
        ? buildVisionMessage({ question, imageBase64, imageMime })
        : normalizeMessages(messages);
      if (!normalized.length) {
        return res.status(400).json({ error: 'missing_messages' });
      }

      const params = {
        Model: isVision ? 'hunyuan-vision' : model,
        Messages: normalized,
        Temperature: temperature,
        TopP: topP,
        Stream: false,
      };

      const result = await client.ChatCompletions(params);
      const reply = result?.Choices?.[0]?.Message?.Content || '';
      res.json({
        reply,
        model: result?.Model,
        usage: result?.Usage,
        raw: result,
      });
    } catch (err) {
      console.error('[chat]', err);
      res.status(500).json({
        error: 'proxy_error',
        message: err?.message || 'Unknown error',
      });
    }
  });
}

module.exports = routes;
