# 数据准备

数据来源：[eCommerce Events History in Cosmetics Shop](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop)。

下载五个月度 CSV 后，将其导入 MySQL 并命名为：

- `2019_oct`
- `2019_nov`
- `2019_dec`
- `2020_jan`
- `2020_feb`

预期字段：

| 字段 | 含义 |
|---|---|
| `event_time` | UTC 行为时间 |
| `event_type` | view/cart/remove_from_cart/purchase |
| `product_id` | 商品编号 |
| `category_id` | 品类编号 |
| `category_code` | 品类编码，缺失严重 |
| `brand` | 品牌 |
| `price` | 行为记录对应价格 |
| `user_id` | 用户编号 |
| `user_session` | 会话编号 |

原始 CSV 和数据库文件不提交至 GitHub。

