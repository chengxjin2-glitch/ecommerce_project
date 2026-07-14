-- ============================================================
-- 02. 数据审计（只检查，不修改原始表）
-- ============================================================

-- 2.1 字段结构与数据类型
DESCRIBE ecommerce_all;

-- 2.2 基础规模和字符串时间范围
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT user_id) AS user_count,
    COUNT(DISTINCT product_id) AS product_count,
    MIN(event_time) AS min_event_time,
    MAX(event_time) AS max_event_time
FROM ecommerce_all;

-- 2.3 行为类型分布
SELECT
    event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS user_count
FROM ecommerce_all
GROUP BY event_type
ORDER BY event_count DESC;

-- 2.4 SQL NULL 检查
SELECT
    COUNT(*) AS total_rows,
    SUM(event_time IS NULL) AS null_event_time,
    SUM(event_type IS NULL) AS null_event_type,
    SUM(product_id IS NULL) AS null_product_id,
    SUM(category_id IS NULL) AS null_category_id,
    SUM(category_code IS NULL) AS null_category_code,
    SUM(brand IS NULL) AS null_brand,
    SUM(price IS NULL) AS null_price,
    SUM(user_id IS NULL) AS null_user_id,
    SUM(user_session IS NULL) AS null_user_session
FROM ecommerce_all;

-- 2.5 空字符串及文本 null 检查
-- CSV 导入后，缺失值可能是空字符串而非 SQL NULL。
SELECT
    SUM(NULLIF(TRIM(event_time), '') IS NULL) AS missing_event_time,
    SUM(NULLIF(TRIM(event_type), '') IS NULL) AS missing_event_type,
    SUM(NULLIF(TRIM(category_code), '') IS NULL) AS missing_category_code,
    SUM(NULLIF(TRIM(brand), '') IS NULL) AS missing_brand,
    SUM(NULLIF(TRIM(user_session), '') IS NULL) AS missing_user_session,
    SUM(LOWER(TRIM(category_code)) = 'null') AS text_null_category,
    SUM(LOWER(TRIM(brand)) = 'null') AS text_null_brand,
    SUM(LOWER(TRIM(user_session)) = 'null') AS text_null_session
FROM ecommerce_all;

-- 2.6 全字段完全重复记录
-- 数据缺少原始 event_id，因此将九个业务字段完全相同作为疑似重复上报规则。
WITH exact_duplicates AS (
    SELECT
        event_time, event_type, product_id, category_id,
        category_code, brand, price, user_id, user_session,
        COUNT(*) AS duplicate_count
    FROM ecommerce_all
    GROUP BY
        event_time, event_type, product_id, category_id,
        category_code, brand, price, user_id, user_session
    HAVING COUNT(*) > 1
)
SELECT
    event_type,
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count - 1) AS extra_rows,
    MAX(duplicate_count) AS max_duplicate_count
FROM exact_duplicates
GROUP BY event_type
ORDER BY extra_rows DESC;

-- 2.7 完全重复率
WITH exact_duplicates AS (
    SELECT
        event_time, event_type, product_id, category_id,
        category_code, brand, price, user_id, user_session,
        COUNT(*) AS duplicate_count
    FROM ecommerce_all
    GROUP BY
        event_time, event_type, product_id, category_id,
        category_code, brand, price, user_id, user_session
    HAVING COUNT(*) > 1
),
duplicate_summary AS (
    SELECT SUM(duplicate_count - 1) AS extra_rows
    FROM exact_duplicates
)
SELECT
    source.total_rows,
    duplicate_summary.extra_rows,
    ROUND(
        duplicate_summary.extra_rows * 100.0
        / NULLIF(source.total_rows, 0),
        6
    ) AS duplicate_rate_pct
FROM (SELECT COUNT(*) AS total_rows FROM ecommerce_all) AS source
CROSS JOIN duplicate_summary;

-- 2.8 非正价格分布
SELECT
    event_type,
    COUNT(*) AS invalid_price_rows,
    SUM(price = 0) AS zero_price_rows,
    SUM(price < 0) AS negative_price_rows,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM ecommerce_all
WHERE price <= 0
GROUP BY event_type
ORDER BY invalid_price_rows DESC;

-- 2.9 时间字符串可转换性检查
SELECT
    COUNT(*) AS total_rows,
    SUM(
        STR_TO_DATE(
            REPLACE(TRIM(event_time), ' UTC', ''),
            '%Y-%m-%d %H:%i:%s'
        ) IS NULL
    ) AS invalid_time_rows
FROM ecommerce_all;

