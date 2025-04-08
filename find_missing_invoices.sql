WITH RECURSIVE number_sequence AS (
    -- 生成 0 到 49 的數字序列，每本發票最多 50 張
    SELECT 0 AS num
    UNION ALL
    SELECT num + 1
    FROM number_sequence
    WHERE num < 49
),
all_possible_invoices AS (
    -- 為每本發票生成所有可能的號碼
    SELECT 
        ib.id,
        ib.track,
        ib.year,
        ib.month,
        ib.begin_number,
        ib.end_number,
        -- 發票號碼：字軌 + (起始號碼 + 數字序列)
        CONCAT(ib.track, '-', LPAD((ib.begin_number + ns.num), 8, '0')) AS invoice_number
    FROM invoice_books ib
    CROSS JOIN number_sequence ns
    WHERE 
        -- 確保生成的號碼在範圍內
        (ib.begin_number + ns.num) <= ib.end_number
        -- 排除 AC-45678989 至 AC-45678999（空白發票）
        AND NOT (
            ib.track = 'AC' 
            AND (ib.begin_number + ns.num) >= 45678989 
            AND (ib.begin_number + ns.num) <= 45678999
        )
)
-- 找出未出現在invoices表中的發票號碼
SELECT 
    api.id,
    api.invoice_number,
    api.track,
    api.year,
    api.month,
    api.begin_number,
    api.end_number
FROM all_possible_invoices api
LEFT JOIN invoices i 
    ON i.invoice_number = api.invoice_number
WHERE i.invoice_number IS NULL
ORDER BY api.track, api.invoice_number;
