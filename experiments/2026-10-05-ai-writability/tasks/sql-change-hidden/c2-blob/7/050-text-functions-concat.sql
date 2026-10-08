SELECT X'6869' || '!', 'a' || X'62', X'31' || X'32', typeof(X'31' || X'32');
SELECT 7 || X'78', X'78' || NULL, length(X'6162' || X'63');
SELECT (X'31' || X'32') = '12', (X'31' || X'32') = X'3132';
