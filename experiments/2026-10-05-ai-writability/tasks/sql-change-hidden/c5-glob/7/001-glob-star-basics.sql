SELECT 'hello' GLOB 'h*', 'hello' GLOB '*o', 'hello' GLOB '*ll*', 'hello' GLOB 'hell', 'hello' GLOB 'ello';
SELECT 'hello' GLOB 'h*l*o', 'hello' GLOB 'h*z*', 'h' GLOB 'h*', 'h' GLOB '*h*';
SELECT '' GLOB '**', '' GLOB 'a*', 'a b' GLOB 'a*b', 'a b' GLOB 'a b';
