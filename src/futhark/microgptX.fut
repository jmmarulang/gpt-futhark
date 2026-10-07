--------- Generic Combinators ---------

def imap 'a : (n: i64) -> (i64 -> a) -> [n]a =
  \n f -> map f (iota n)

def imap1 = imap

def imap2 'a : (m: i64) -> (n: i64) -> (i64 -> i64 -> a) -> [m][n]a =
  \m n f -> imap m (\i -> imap n (f i))

def imap3 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (i64 -> i64 -> i64 -> a) -> [m][n][k]a =
  \m n k f -> imap m (\i -> imap2 n k (f i))

def imap4 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l]a =
  \m n k l f -> imap m (\i -> imap3 n k l (f i))

def imap5 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (t: i64)
-> (i64 -> i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l][t]a =
  \m n k l t f -> imap m (\i -> imap4 n k l t (f i))

def imap6 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (t: i64)
-> (p: i64)
-> (i64 -> i64 -> i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l][t][p]a =
  \m n k l t p f -> imap m (\i -> imap5 n k l t p (f i))

def imap7 'a : (m: i64)
-> (n: i64)
-> (k: i64)
-> (l: i64)
-> (t: i64)
-> (p: i64)
-> (q: i64)
-> (i64 -> i64 -> i64 -> i64 -> i64 -> i64 -> i64 -> a) -> [m][n][k][l][t][p][q]a =
  \m n k l t p q f -> imap m (\i -> imap6 n k l t p q (f i))

def unzip7 [n] 'a 'b 'c 'd 'e 'f 'g : (a: [n](a, b, c, d, e, f, g)) -> ([n]a, [n]b, [n]c, [n]d, [n]e, [n]f, [n]g) =
  \a ->
    ( imap n (\i -> a[i].0)
    , imap n (\i -> a[i].1)
    , imap n (\i -> a[i].2)
    , imap n (\i -> a[i].3)
    , imap n (\i -> a[i].4)
    , imap n (\i -> a[i].5)
    , imap n (\i -> a[i].6)
    )

--==== MGPT Module ====--
module nn (F: real) = {
  type real = F.t

  def fromi64 (n: i64) = F.from_fraction n 1 -- why from fraction?
  def zero = fromi64 0
  def one = fromi64 1

  def isum1 : (m: i64) -> (i64 -> real) -> real =
    \m f -> loop r = zero for i < m do r F.+ f i

  def isum2 : (m: i64)
  -> (n: i64)
  -> (i64 -> i64 -> real) -> real =
    \m n f -> loop r = zero for i < m do r F.+ isum1 n (f i)

  def isum3 : (m: i64)
  -> (n: i64)
  -> (k: i64)
  -> (i64 -> i64 -> i64 -> real) -> real =
    \n m k f -> loop r = zero for i < n do r F.+ isum2 m k (f i)

  def isum4 : (m: i64)
  -> (n: i64)
  -> (k: i64)
  -> (l: i64)
  -> (i64 -> i64 -> i64 -> i64 -> real) -> real =
    \n m k l f -> loop r = zero for i < n do r F.+ isum3 m k l (f i)

  def isum5 : (m: i64)
  -> (n: i64)
  -> (k: i64)
  -> (l: i64)
  -> (t: i64)
  -> (i64 -> i64 -> i64 -> i64 -> i64 -> real) -> real =
    \n m k l t f -> loop r = zero for i < n do r F.+ isum4 m k l t (f i)

  def sum (a: []real) : real =
    reduce (F.+) zero a

  def imaximum1 : (m: i64) -> (i64 -> real) -> real =
    \m f -> F.maximum (imap1 m f)

  def imaximum2 : (m: i64)
  -> (n: i64)
  -> (i64 -> i64 -> real) -> real =
    \m n f -> F.maximum (imap1 m (\i -> imaximum1 n (f i)))

  def isoftmax1 (m: i64) (f : i64 -> real) : [m]real =
    #[inline]
    let max = imaximum1 m f
    let exps = imap1 m (\x -> F.exp((f x) F.+ F.neg max))
    let scale = isum1 m (\x -> exps[x])
    in imap1 m (\x -> exps[x] F./ scale)

  --==== 2d cases ====--
  def sum2d (a: [][]real) : real =
    sum (map sum a)

  --==== Logistics ====--
  def logistics : real -> real =
    \e -> one F./ (one F.+ F.exp (F.neg e))

  def sgnp : real -> real = \e -> F.sgn (F.max e zero)

  def indicatorp : real -> real = sgnp

  --==== This is the generated function. ====--

  def forward_seq : (mask: [16][16]real)
    -> (wp: [16][16]real)
    -> (wqry: [16][16]real)
    -> (wkey: [16][16]real)
    -> (wval: [16][16]real)
    -> (wo: [16][16]real)
    -> (wu: [64][16]real)
    -> (wd: [16][64]real)
    -> (wc: [27][16]real)
    -> (ws: [1][16][16]real)
    -- -> [16][27]real =
    -> [1][16][27]real =
    #[unsafe]
    \(mask: [16][16]real) (wp: [16][16]real)
    (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
    (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
    (wc: [27][16]real) (ws: [1][16][16]real) ->

(let x0 = (imap2 1 16 (\i22 i23 -> (imap1 16 (\i24 -> (wp[i23][i24] F.+ ws[i22][i23][i24])))))
in (let x1 = (imap2 1 16 (\i25 i26 -> (let x27 = (imap1 16 (\i31 -> (x0[i25][i26][i31] F.* x0[i25][i26][i31])))
in (let x28 = ((isum1 16 (\i32 -> x27[i32])) F./ fromi64 16)
in (let x29 = (F.sqrt (x28 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i30 -> (x0[i25][i26][i30] F.* (one F./ x29)))))))))
in (let x2 = (imap2 1 16 (\i33 i34 -> (let x35 = (imap1 16 (\i39 -> (x1[i33][i34][i39] F.* x1[i33][i34][i39])))
in (let x36 = ((isum1 16 (\i40 -> x35[i40])) F./ fromi64 16)
in (let x37 = (F.sqrt (x36 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i38 -> (x1[i33][i34][i38] F.* (one F./ x37)))))))))
in (let x3 = (imap2 1 16 (\i41 i42 -> (imap1 16 (\i43 -> (isum1 16 (\i44 -> (wkey[i43][i44] F.* x2[i41][i42][i44])))))))
in (let x4 = (imap2 1 16 (\i45 i46 -> (imap1 16 (\i47 -> (isum1 16 (\i48 -> (wqry[i47][i48] F.* x2[i45][i46][i48])))))))
in (let x5 = (imap2 1 16 (\i49 i50 -> (imap1 16 (\i51 -> (isum1 16 (\i52 -> (wval[i51][i52] F.* x2[i49][i50][i52])))))))
in (let x6 = (imap2 1 4 (\i53 i54 -> (imap2 16 4 (\i55 i56 -> x3[i53][i55][((i54 * 4) + i56)]))))
in (let x7 = (imap2 1 4 (\i57 i58 -> (imap2 16 4 (\i59 i60 -> x4[i57][i59][((i58 * 4) + i60)]))))
in (let x8 = (imap2 1 4 (\i61 i62 -> (imap2 16 4 (\i63 i64 -> x5[i61][i63][((i62 * 4) + i64)]))))
in (let x9 = (imap2 1 4 (\i65 i66 -> (imap1 16 (\i67 -> (imap1 16 (\i68 -> (isum1 4 (\i69 -> (x7[i65][i66][i67][i69] F.* x6[i65][i66][i68][i69])))))))))
in (let x10 = (imap2 1 4 (\i70 i71 -> (imap2 16 16 (\i72 i73 -> (x9[i70][i71][i72][i73] F.+ mask[i72][i73])))))
in (let x11 = (imap2 1 4 (\i74 i75 -> (imap1 16 (\i76 -> (let x78 = (isoftmax1 16 (\i77 -> x10[i74][i75][i76][i77]))
in (imap1 16 (\i79 -> x78[i79])))))))
in (let x12 = (imap2 1 4 (\i80 i81 -> (imap1 16 (\i82 -> (imap1 4 (\i83 -> (isum1 16 (\i84 -> (x11[i80][i81][i82][i84] F.* x8[i80][i81][i84][i83])))))))))
in (let x13 = (imap2 1 16 (\i85 i86 -> (imap1 16 (\i87 -> x12[i85][(i87 / 4)][i86][(i87 % 4)]))))
in (let x14 = (imap2 1 16 (\i88 i89 -> (imap1 16 (\i90 -> (isum1 16 (\i91 -> (wo[i90][i91] F.* x13[i88][i89][i91])))))))
in (let x15 = (imap3 1 16 16 (\i92 i93 i94 -> (x14[i92][i93][i94] F.+ x1[i92][i93][i94])))
in (let x16 = (imap2 1 16 (\i95 i96 -> (let x97 = (imap1 16 (\i101 -> (x15[i95][i96][i101] F.* x15[i95][i96][i101])))
in (let x98 = ((isum1 16 (\i102 -> x97[i102])) F./ fromi64 16)
in (let x99 = (F.sqrt (x98 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i100 -> (x15[i95][i96][i100] F.* (one F./ x99)))))))))
in (let x17 = (imap2 1 16 (\i103 i104 -> (imap1 64 (\i105 -> (isum1 16 (\i106 -> (wu[i105][i106] F.* x16[i103][i104][i106])))))))
in (let x18 = (imap3 1 16 64 (\i107 i108 i109 -> (F.max x17[i107][i108][i109] zero)))
in (let x19 = (imap2 1 16 (\i110 i111 -> (imap1 16 (\i112 -> (isum1 64 (\i113 -> (wd[i112][i113] F.* x18[i110][i111][i113])))))))
in (let x20 = (imap3 1 16 16 (\i114 i115 i116 -> (x19[i114][i115][i116] F.+ x15[i114][i115][i116])))
in (imap1 1 (\i21 -> (imap1 16 (\i117 -> (imap1 27 (\i118 -> (isum1 16 (\i119 -> (wc[i118][i119] F.* x20[i21][i117][i119]))))))))))))))))))))))))))))))


  def cal_loss : (mask: [16][16]real)
    -> (wp: [16][16]real)
    -> (wqry: [16][16]real)
    -> (wkey: [16][16]real)
    -> (wval: [16][16]real)
    -> (wo: [16][16]real)
    -> (wu: [64][16]real)
    -> (wd: [16][64]real)
    -> (wc: [27][16]real)
    -> (ws: [1][16][16]real)
    -> (target: [1][16][27]real)
    -> real =
    #[unsafe]
    \(mask: [16][16]real) (wp: [16][16]real)
    (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
    (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
    (wc: [27][16]real) (ws: [1][16][16]real) (target: [1][16][27]real) ->

((isum1 1 (\i0 -> (let x1 = (imap2 16 16 (\i26 i27 -> (wp[i26][i27] F.+ ws[i0][i26][i27])))
in (let x2 = (imap1 16 (\i28 -> (let x29 = (imap1 16 (\i33 -> (x1[i28][i33] F.* x1[i28][i33])))
in (let x30 = ((isum1 16 (\i34 -> x29[i34])) F./ fromi64 16)
in (let x31 = (F.sqrt (x30 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i32 -> (x1[i28][i32] F.* (one F./ x31)))))))))
in (let x3 = (imap1 16 (\i35 -> (let x36 = (imap1 16 (\i40 -> (x2[i35][i40] F.* x2[i35][i40])))
in (let x37 = ((isum1 16 (\i41 -> x36[i41])) F./ fromi64 16)
in (let x38 = (F.sqrt (x37 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i39 -> (x2[i35][i39] F.* (one F./ x38)))))))))
in (let x4 = (imap1 16 (\i42 -> (imap1 16 (\i43 -> (isum1 16 (\i44 -> (wkey[i43][i44] F.* x3[i42][i44])))))))
in (let x5 = (imap1 16 (\i45 -> (imap1 16 (\i46 -> (isum1 16 (\i47 -> (wqry[i46][i47] F.* x3[i45][i47])))))))
in (let x6 = (imap1 16 (\i48 -> (imap1 16 (\i49 -> (isum1 16 (\i50 -> (wval[i49][i50] F.* x3[i48][i50])))))))
in (let x7 = (imap1 4 (\i51 -> (imap1 16 (\i52 -> (imap1 4 (\i53 -> x4[i52][((i51 * 4) + i53)]))))))
in (let x8 = (imap1 4 (\i54 -> (imap1 16 (\i55 -> (imap1 4 (\i56 -> x5[i55][((i54 * 4) + i56)]))))))
in (let x9 = (imap1 4 (\i57 -> (imap1 16 (\i58 -> (imap1 4 (\i59 -> x6[i58][((i57 * 4) + i59)]))))))
in (let x10 = (imap1 4 (\i60 -> (let x61 = (imap1 16 (\i65 -> (imap1 16 (\i66 -> (isum1 4 (\i67 -> (x8[i60][i65][i67] F.* x7[i60][i66][i67])))))))
in (let x62 = (imap2 16 16 (\i68 i69 -> ((x61[i68][i69] F./ fromi64 2) F.+ mask[i68][i69])))
in (let x63 = (imap1 16 (\i70 -> (let x72 = (isoftmax1 16 (\i71 -> x62[i70][i71]))
in (imap1 16 (\i73 -> x72[i73])))))
in (imap1 16 (\i64 -> (imap1 4 (\i74 -> (isum1 16 (\i75 -> (x63[i64][i75] F.* x9[i60][i75][i74]))))))))))))
in (let x11 = (imap1 16 (\i76 -> (imap1 16 (\i77 -> x10[(i77 / 4)][i76][(i77 % 4)]))))
in (let x12 = (imap1 16 (\i78 -> (imap1 16 (\i79 -> (isum1 16 (\i80 -> (wo[i79][i80] F.* x11[i78][i80])))))))
in (let x13 = (imap2 16 16 (\i81 i82 -> (x12[i81][i82] F.+ x2[i81][i82])))
in (let x14 = (imap1 16 (\i83 -> (let x84 = (imap1 16 (\i88 -> (x13[i83][i88] F.* x13[i83][i88])))
in (let x85 = ((isum1 16 (\i89 -> x84[i89])) F./ fromi64 16)
in (let x86 = (F.sqrt (x85 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i87 -> (x13[i83][i87] F.* (one F./ x86)))))))))
in (let x15 = (imap1 16 (\i90 -> (imap1 64 (\i91 -> (isum1 16 (\i92 -> (wu[i91][i92] F.* x14[i90][i92])))))))
in (let x16 = (imap2 16 64 (\i93 i94 -> (F.max x15[i93][i94] zero)))
in (let x17 = (imap1 16 (\i95 -> (imap1 16 (\i96 -> (isum1 64 (\i97 -> (wd[i96][i97] F.* x16[i95][i97])))))))
in (let x18 = (imap2 16 16 (\i98 i99 -> (x17[i98][i99] F.+ x13[i98][i99])))
in (let x19 = (imap1 16 (\i100 -> (imap1 27 (\i101 -> (isum1 16 (\i102 -> (wc[i101][i102] F.* x18[i100][i102])))))))
in ((isum1 16 (\i20 -> (let x21 = (imap1 27 (\i25 -> (F.log (let x24 = (isoftmax1 27 (\i23 -> x19[i20][i23]))
in x24[i25]))))
in (F.neg (isum1 27 (\i22 -> (x21[i22] F.* target[i0][i20][i22]))))))) F./ fromi64 16)))))))))))))))))))))) F./ fromi64 1)


--   def grad_loss : (mask: [16][16]real)
--     -> (wpe: [16][16]real)
--     -> (wqry: [16][16]real)
--     -> (wkey: [16][16]real)
--     -> (wval: [16][16]real)
--     -> (wout: [16][16]real)
--     -> (wup: [64][16]real)
--     -> (wdown: [16][64]real)
--     -> (wvoc: [27][16]real)
--     -> (wseq: [16][16]real)
--     -> (target: [16][27]real)
--     -> ([16][16]real, -- dwpe
--         [16][16]real, -- dwqry
--         [16][16]real, -- dwkey
--         [16][16]real, -- dwval
--         [16][16]real, -- dwout
--         [64][16]real, -- dwup
--         [16][64]real, -- dwdown
--         [27][16]real, -- dwvoc
--         [16][16]real -- dwseq
--         ) =
--     #[unsafe]
--     \(mask: [16][16]real) (wpe: [16][16]real)
--     (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
--     (wout: [16][16]real) (wup: [64][16]real) (wdown: [16][64]real)
--     (wvoc: [27][16]real) (wseq: [16][16]real) (target: [16][27]real) ->
--     -- (wpe, wqry, wkey, wval, wout, wup, wdown, wvoc, wseq)

-- let x0 = (imap2 16 16 (\i1 i2 -> (wpe[i1][i2] F.+ wseq[i1][i2])))
-- let x3 = (imap1 16 (\i4 -> (let x5 = ((isum1 16 (\i8 -> (x0[i4][i8] F.* x0[i4][i8]))) F./ fromi64 16)
-- in (let x6 = (F.sqrt (x5 F.+ (one F./ fromi64 100000)))
-- in (imap1 16 (\i7 -> (x0[i4][i7] F.* (one F./ x6))))))))
-- let x9 = (imap1 16 (\i10 -> (let x11 = ((isum1 16 (\i14 -> (x3[i10][i14] F.* x3[i10][i14]))) F./ fromi64 16)
-- in (let x12 = (F.sqrt (x11 F.+ (one F./ fromi64 100000)))
-- in (imap1 16 (\i13 -> (x3[i10][i13] F.* (one F./ x12))))))))
-- let x15 = (imap1 16 (\i16 -> (imap1 16 (\i17 -> (isum1 16 (\i18 -> (wqry[i17][i18] F.* x9[i16][i18])))))))
-- let x19 = (imap1 16 (\i20 -> (imap1 16 (\i21 -> (isum1 16 (\i22 -> (wkey[i21][i22] F.* x9[i20][i22])))))))
-- let x23 = (imap1 16 (\i24 -> (imap1 16 (\i25 -> (isum1 16 (\i26 -> (wval[i25][i26] F.* x9[i24][i26])))))))
-- let x27 = (imap1 4 (\i28 -> (imap1 16 (\i29 -> (imap1 4 (\i30 -> x15[i29][((i28 * 4) + i30)]))))))
-- let x31 = (imap1 4 (\i32 -> (imap1 16 (\i33 -> (imap1 4 (\i34 -> x19[i33][((i32 * 4) + i34)]))))))
-- let x35 = (imap1 4 (\i36 -> (imap1 16 (\i37 -> (imap1 4 (\i38 -> x23[i37][((i36 * 4) + i38)]))))))
-- let x39 = (imap1 4 (\i40 -> (let x41 = (imap1 16 (\i45 -> (imap1 16 (\i46 -> (isum1 4 (\i47 -> (x27[i40][i45][i47] F.* x31[i40][i46][i47])))))))
-- in (let x42 = (imap2 16 16 (\i48 i49 -> ((x41[i48][i49] F./ fromi64 2) F.+ mask[i48][i49])))
-- in (let x43 = (imap1 16 (\i50 -> (let x52 = (isoftmax1 16 (\i51 -> x42[i50][i51]))
-- in (imap1 16 (\i53 -> x52[i53])))))
-- in (imap1 16 (\i44 -> (imap1 4 (\i54 -> (isum1 16 (\i55 -> (x43[i44][i55] F.* x35[i40][i55][i54]))))))))))))
-- let x56 = (imap1 16 (\i57 -> (imap1 16 (\i58 -> x39[(i58 / 4)][i57][(i58 % 4)]))))
-- let x59 = (imap1 16 (\i60 -> (imap1 16 (\i61 -> (isum1 16 (\i62 -> (wout[i61][i62] F.* x56[i60][i62])))))))
-- let x63 = (imap2 16 16 (\i64 i65 -> (x59[i64][i65] F.+ x3[i64][i65])))
-- let x66 = (imap1 16 (\i67 -> (let x68 = ((isum1 16 (\i71 -> (x63[i67][i71] F.* x63[i67][i71]))) F./ fromi64 16)
-- in (let x69 = (F.sqrt (x68 F.+ (one F./ fromi64 100000)))
-- in (imap1 16 (\i70 -> (x63[i67][i70] F.* (one F./ x69))))))))
-- let x72 = (imap1 16 (\i73 -> (imap1 64 (\i74 -> (isum1 16 (\i75 -> (wup[i74][i75] F.* x66[i73][i75])))))))
-- let x76 = (imap2 16 64 (\i77 i78 -> (F.max x72[i77][i78] zero)))
-- let x79 = (imap1 16 (\i80 -> (imap1 16 (\i81 -> (isum1 64 (\i82 -> (wdown[i81][i82] F.* x76[i80][i82])))))))
-- let x83 = (imap2 16 16 (\i84 i85 -> (x79[i84][i85] F.+ x63[i84][i85])))
-- let x86 = (imap1 16 (\i87 -> (imap1 27 (\i88 -> (isum1 16 (\i89 -> (wvoc[i88][i89] F.* x83[i87][i89])))))))
-- let x90 = (imap1 16 (\i91 -> (one F./ fromi64 16)))
-- let x92 = (imap1 16 (\i93 -> (imap1 27 (\i96 -> (F.log (let x95 = (isoftmax1 27 (\i94 -> x86[i93][i94]))
-- in x95[i96]))))))
-- let x97 = (imap1 16 (\i98 -> (imap1 27 (\i99 -> ((F.neg x90[i98]) F.* target[i98][i99])))))
-- let x100 = (imap1 16 (\i101 -> (let x103 = (isoftmax1 27 (\i102 -> x86[i101][i102]))
-- in (imap1 27 (\i104 -> x103[i104])))))
-- let x105 = (imap1 16 (\i106 -> (imap1 27 (\i109 -> (x97[i106][i109] F.* (one F./ (let x108 = (isoftmax1 27 (\i107 -> x86[i106][i107]))
-- in x108[i109])))))))
-- let x110 = (imap1 16 (\i111 -> (isum1 27 (\i112 -> (x105[i111][i112] F.* x100[i111][i112])))))
-- let x113 = (imap1 16 (\i114 -> (imap1 27 (\i115 -> (x100[i114][i115] F.* (x105[i114][i115] F.+ (F.neg x110[i114])))))))
-- let x116 = (imap1 16 (\i117 -> (imap1 16 (\i118 -> (isum1 27 (\i119 -> (wvoc[i119][i118] F.* x113[i117][i119])))))))
-- let x120 = (imap1 16 (\i121 -> (imap1 64 (\i122 -> (isum1 16 (\i123 -> (wdown[i123][i122] F.* x116[i121][i123])))))))
-- let x124 = (imap2 16 64 (\i125 i126 -> ((indicatorp x72[i125][i126]) F.* x120[i125][i126])))
-- let x127 = (imap1 16 (\i128 -> (imap1 16 (\i129 -> (isum1 64 (\i130 -> (wup[i130][i129] F.* x124[i128][i130])))))))
-- let x131 = (imap1 16 (\i132 -> (imap1 16 (\i133 -> (x63[i132][i133] F.* x63[i132][i133])))))
-- let x134 = (imap1 16 (\i135 -> ((isum1 16 (\i136 -> x131[i135][i136])) F./ fromi64 16)))
-- let x137 = (imap1 16 (\i138 -> (F.sqrt (x134[i138] F.+ (one F./ fromi64 100000)))))
-- let x139 = (imap1 16 (\i140 -> (F.neg ((one F./ x137[i140]) F.* ((isum1 16 (\i141 -> (x63[i140][i141] F.* x127[i140][i141]))) F.* (one F./ x137[i140]))))))
-- let x142 = (imap1 16 (\i143 -> (x139[i143] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x134[i143] F.+ (one F./ fromi64 100000))))))))
-- let x144 = (imap1 16 (\i145 -> (imap1 16 (\i146 -> (x142[i145] F./ fromi64 16)))))
-- let x147 = (imap1 16 (\i148 -> (imap1 16 (\i149 -> (x116[i148][i149] F.+ (((x127[i148][i149] F.* (one F./ x137[i148])) F.+ (x63[i148][i149] F.* x144[i148][i149])) F.+ (x144[i148][i149] F.* x63[i148][i149])))))))
-- let x150 = (imap1 16 (\i151 -> (imap1 16 (\i152 -> (isum1 16 (\i153 -> (wout[i153][i152] F.* x147[i151][i153])))))))
-- let x154 = (imap1 4 (\i155 -> (imap1 16 (\i156 -> (imap1 4 (\i157 -> x150[i156][((i155 * 4) + i157)]))))))
-- let x158 = (imap1 4 (\i159 -> (imap1 16 (\i160 -> (imap1 16 (\i161 -> (isum1 4 (\i162 -> (x27[i159][i160][i162] F.* x31[i159][i161][i162])))))))))
-- let x163 = (imap1 4 (\i164 -> (imap2 16 16 (\i165 i166 -> ((x158[i164][i165][i166] F./ fromi64 2) F.+ mask[i165][i166])))))
-- let x167 = (imap1 4 (\i168 -> (imap1 16 (\i169 -> (let x171 = (isoftmax1 16 (\i170 -> x163[i168][i169][i170]))
-- in (imap1 16 (\i172 -> x171[i172])))))))
-- let x173 = (imap1 4 (\i174 -> (imap1 16 (\i175 -> (imap1 16 (\i176 -> (isum1 4 (\i177 -> (x154[i174][i175][i177] F.* x35[i174][i176][i177])))))))))
-- let x178 = (imap1 4 (\i179 -> (imap1 16 (\i180 -> (imap1 16 (\i181 -> x173[i179][i180][i181]))))))
-- let x182 = (imap1 4 (\i183 -> (imap1 16 (\i184 -> (isum1 16 (\i185 -> (x178[i183][i184][i185] F.* x167[i183][i184][i185])))))))
-- let x186 = (imap1 4 (\i187 -> (imap1 16 (\i188 -> (imap1 16 (\i189 -> (x167[i187][i188][i189] F.* (x178[i187][i188][i189] F.+ (F.neg x182[i187][i188])))))))))
-- let x190 = (imap1 4 (\i191 -> (imap2 16 16 (\i192 i193 -> (x186[i191][i192][i193] F./ fromi64 2)))))
-- let x194 = (imap1 4 (\i195 -> (imap1 16 (\i196 -> (imap1 4 (\i197 -> (isum1 16 (\i198 -> (x167[i195][i198][i196] F.* x154[i195][i198][i197])))))))))
-- let x199 = (imap1 4 (\i200 -> (imap1 16 (\i201 -> (imap1 4 (\i202 -> (isum1 16 (\i203 -> (x27[i200][i203][i202] F.* x190[i200][i203][i201])))))))))
-- let x204 = (imap1 4 (\i205 -> (imap1 16 (\i206 -> (imap1 4 (\i207 -> (isum1 16 (\i208 -> (x190[i205][i206][i208] F.* x31[i205][i208][i207])))))))))
-- let x209 = (imap1 16 (\i210 -> (imap1 16 (\i211 -> x194[(i211 / 4)][i210][(i211 % 4)]))))
-- let x212 = (imap1 16 (\i213 -> (imap1 16 (\i214 -> x199[(i214 / 4)][i213][(i214 % 4)]))))
-- let x215 = (imap1 16 (\i216 -> (imap1 16 (\i217 -> x204[(i217 / 4)][i216][(i217 % 4)]))))
-- let x218 = (imap1 16 (\i219 -> (imap1 16 (\i220 -> (((isum1 16 (\i221 -> (wval[i221][i220] F.* x209[i219][i221]))) F.+ (isum1 16 (\i222 -> (wkey[i222][i220] F.* x212[i219][i222])))) F.+ (isum1 16 (\i223 -> (wqry[i223][i220] F.* x215[i219][i223]))))))))
-- let x224 = (imap1 16 (\i225 -> (imap1 16 (\i226 -> (x3[i225][i226] F.* x3[i225][i226])))))
-- let x227 = (imap1 16 (\i228 -> ((isum1 16 (\i229 -> x224[i228][i229])) F./ fromi64 16)))
-- let x230 = (imap1 16 (\i231 -> (F.sqrt (x227[i231] F.+ (one F./ fromi64 100000)))))
-- let x232 = (imap1 16 (\i233 -> (F.neg ((one F./ x230[i233]) F.* ((isum1 16 (\i234 -> (x3[i233][i234] F.* x218[i233][i234]))) F.* (one F./ x230[i233]))))))
-- let x235 = (imap1 16 (\i236 -> (x232[i236] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x227[i236] F.+ (one F./ fromi64 100000))))))))
-- let x237 = (imap1 16 (\i238 -> (imap1 16 (\i239 -> (x235[i238] F./ fromi64 16)))))
-- let x240 = (imap1 16 (\i241 -> (imap1 16 (\i242 -> (x147[i241][i242] F.+ (((x218[i241][i242] F.* (one F./ x230[i241])) F.+ (x3[i241][i242] F.* x237[i241][i242])) F.+ (x237[i241][i242] F.* x3[i241][i242])))))))
-- let x243 = (imap1 16 (\i244 -> (imap1 16 (\i245 -> (x0[i244][i245] F.* x0[i244][i245])))))
-- let x246 = (imap1 16 (\i247 -> ((isum1 16 (\i248 -> x243[i247][i248])) F./ fromi64 16)))
-- let x249 = (imap1 16 (\i250 -> (F.sqrt (x246[i250] F.+ (one F./ fromi64 100000)))))
-- let x251 = (imap1 16 (\i252 -> (F.neg ((one F./ x249[i252]) F.* ((isum1 16 (\i253 -> (x0[i252][i253] F.* x240[i252][i253]))) F.* (one F./ x249[i252]))))))
-- let x254 = (imap1 16 (\i255 -> (x251[i255] F.* (one F./ ((one F.+ one) F.* (F.sqrt (x246[i255] F.+ (one F./ fromi64 100000))))))))
-- let x256 = (imap1 16 (\i257 -> (imap1 16 (\i258 -> (x254[i257] F./ fromi64 16)))))
-- let x259 = (imap1 16 (\i260 -> (imap1 16 (\i261 -> (((x240[i260][i261] F.* (one F./ x249[i260])) F.+ (x0[i260][i261] F.* x256[i260][i261])) F.+ (x256[i260][i261] F.* x0[i260][i261]))))))

-- let dmask = (imap2 16 16 (\i263 i264 -> (isum1 4 (\i262 -> x186[i262][i263][i264]))))
-- let dwpe = (imap2 16 16 (\i265 i266 -> x259[i265][i266]))
-- let dwqry = (imap1 16 (\i267 -> (imap1 16 (\i268 -> (isum1 16 (\i269 -> (x215[i269][i267] F.* x9[i269][i268])))))))
-- let dwkey = (imap1 16 (\i270 -> (imap1 16 (\i271 -> (isum1 16 (\i272 -> (x212[i272][i270] F.* x9[i272][i271])))))))
-- let dwval = (imap1 16 (\i273 -> (imap1 16 (\i274 -> (isum1 16 (\i275 -> (x209[i275][i273] F.* x9[i275][i274])))))))
-- let dwout = (imap1 16 (\i276 -> (imap1 16 (\i277 -> (isum1 16 (\i278 -> (x147[i278][i276] F.* x56[i278][i277])))))))
-- let dwup = (imap1 64 (\i279 -> (imap1 16 (\i280 -> (isum1 16 (\i281 -> (x124[i281][i279] F.* x66[i281][i280])))))))
-- let dwdown = (imap1 16 (\i282 -> (imap1 64 (\i283 -> (isum1 16 (\i284 -> (x116[i284][i282] F.* x76[i284][i283])))))))
-- let dwvoc = (imap1 27 (\i285 -> (imap1 16 (\i286 -> (isum1 16 (\i287 -> (x113[i287][i285] F.* x83[i287][i286])))))))
-- let dwseq = (imap2 16 16 (\i288 i289 -> x259[i288][i289]))
-- let dtarget = (imap1 16 (\i290 -> (imap1 27 (\i291 -> (F.neg (x92[i290][i291] F.* x90[i290]))))))

-- in (dwpe, dwqry, dwkey, dwval, dwout, dwup, dwdown, dwvoc, dwseq)
}


module nn64 = nn f64

type params = {
  wte:   [27][16]f64, -- token embeddings
  wpe:   [16][16]f64, -- position embeddings
  wqry:  [16][16]f64, -- query weights
  wkey:  [16][16]f64, -- key weights
  wval:  [16][16]f64, -- value weights
  wout:  [16][16]f64, -- output weights
  wup:   [64][16]f64, -- MLP up-projection
  wdown: [16][64]f64, -- MLP down-projection
  wvoc:  [27][16]f64  -- output projection
}

entry to_params (wte: [27][16]f64)  (wpe: [16][16]f64)
    (wqry: [16][16]f64) (wkey: [16][16]f64) (wval: [16][16]f64)
    (wout: [16][16]f64) (wup: [64][16]f64) (wdown: [16][64]f64)
    (wvoc: [27][16]f64) : params =
    {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc}

def from_params (p : params) :
  (
  [27][16]f64, -- dwte
  [16][16]f64, -- dwpe
  [16][16]f64, -- dwqry
  [16][16]f64, -- dwkey
  [16][16]f64, -- dwval
  [16][16]f64, -- dwout
  [64][16]f64, -- dwup
  [16][64]f64, -- dwdown
  [27][16]f64, -- dwvoc
  ) =
  let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
  in (wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc)

entry forward_seq (p : params) (tokens : [1][16]i64) (mask : [16][16]f64) : [1][16][27]f64 =
   let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
   let ws = (imap3 1 16 16 (\i j k -> wte[tokens[i][j]][k]))
   in nn64.forward_seq mask wpe wqry wkey wval wout wup wdown wvoc ws

def cal_target (n : i64) (tokens : [1][16]i64) : [1][16][27]f64 =
  imap3 1 16 27 (\i j k -> (if ((j < (n - 1)) && (tokens[i][j + 1] == k)) then 1 else 0))

entry cal_loss (dl : i64) (p : params) (tokens : [1][16]i64) (mask : [16][16]f64) : f64 =
   let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
   let target = cal_target dl tokens
   let ws = (imap3 1 16 16 (\i j k -> wte[tokens[i][j]][k]))
   in nn64.cal_loss mask wpe wqry wkey wval wout wup wdown wvoc ws target

-- def adam_opt_w [n] [m] (w : [n][m]f64) (mw : [n][m]f64) (vw : [n][m]f64)
--   (dw : [n][m]f64) (step : i64) (lt_r : f64):
--   ([n][m]f64, [n][m]f64, [n][m]f64) =
--   let new_mw = imap2 n m (\i j ->
--     0.85 * mw[i][j] + ((1 - 0.85) * dw[i][j]))
--   let new_vw = imap2 n m (\i j ->
--     0.99 * vw[i][j] + ((1 - 0.99) * dw[i][j] * dw[i][j]))
--   let m_hat = imap2 n m (\i j ->
--     new_mw[i][j] / (1 - 0.85 ** ((nn64.fromi64 step) + 1)))
--   let v_hat = imap2 n m (\i j ->
--     new_vw[i][j] / (1 - (0.99 ** ((nn64.fromi64 step) + 1))))
--   let new_w = imap2 n m (\i j ->
--     w[i][j] - (lt_r * m_hat[i][j] / ((v_hat[i][j] ** 0.5) + 0.00000001)))
--   in (new_w, new_mw, new_vw)

-- def adam_opt (p : params) (mp : params) (vp : params)
--   (dp : params) (step : i64) n :
--   (params,  params,  params) =
--   let lt_r = 0.01 * (1 - (nn64.fromi64 step) / (nn64.fromi64 n))
--   let (wte, mwte, vwte) =
--     adam_opt_w p.wte mp.wte vp.wte dp.wte step lt_r
--   let (wpe, mwpe, vwpe) =
--     adam_opt_w p.wpe mp.wpe vp.wpe dp.wpe step lt_r
--   let (wqry, mwqry, vwqry) =
--     adam_opt_w p.wqry mp.wqry vp.wqry dp.wqry step lt_r
--   let (wkey, mwkey, vwkey) =
--     adam_opt_w p.wkey mp.wkey vp.wkey dp.wkey step lt_r
--   let (wval, mwval, vwval) =
--     adam_opt_w p.wval mp.wval vp.wval dp.wval step lt_r
--   let (wout, mwout, vwout) =
--     adam_opt_w p.wout mp.wout vp.wout dp.wout step lt_r
--   let (wup, mwup, vwup) =
--     adam_opt_w p.wup mp.wup vp.wup dp.wup step lt_r
--   let (wdown, mwdown, vwdown) =
--     adam_opt_w p.wdown mp.wdown vp.wdown dp.wdown step lt_r
--   let (wvoc, mwvoc, vwvoc) =
--     adam_opt_w p.wvoc mp.wvoc vp.wvoc dp.wvoc step lt_r
--   let p' = to_params wte wpe wqry wkey wval wout wup wdown wvoc
--   let mp' = to_params mwte mwpe mwqry mwkey mwval mwout mwup mwdown mwvoc
--   let vp' = to_params vwte vwpe vwqry vwkey vwval vwout vwup vwdown vwvoc
--   in (p', mp', vp')

-- def grad_loss (dl : i64) (p : params) (tokens : [16]i64) (mask : [16][16]f64) :
--         (
--         [27][16]f64, -- dwte
--         [16][16]f64, -- dwpe
--         [16][16]f64, -- dwqry
--         [16][16]f64, -- dwkey
--         [16][16]f64, -- dwval
--         [16][16]f64, -- dwout
--         [64][16]f64, -- dwup
--         [16][64]f64, -- dwdown
--         [27][16]f64, -- dwvoc
--         ) =
--    let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
--    -- cal targets
--    let targets = cal_target dl tokens
--    -- cal voc embedding
--    let wseq = (imap2 16 16 (\m n -> wte[tokens[m]][n]))
--    -- cal gradient
--    let (dwpe, dwqry, dwkey, dwval, dwout, dwup, dwdown, dwvoc, dwseq) =
--     nn64.grad_loss mask wpe wqry wkey wval wout wup wdown wvoc wseq targets
--    let dwte = (imap2 27 16 (\m n -> nn64.isum1 16 (\k -> if (tokens[k] == m) then dwseq[k][n] else nn64.zero)))
--    in  (dwte, dwpe, dwqry, dwkey, dwval, dwout, dwup, dwdown, dwvoc)


-- def cal_step (dl : i64) (p : params) (mp : params) (vp : params)
--   (tokens : [16]i64) (mask : [16][16]f64)
--   (step : i64) n :
--   (params,  params,  params , f64) =
--   let loss = cal_loss dl p tokens mask
--   -- cal gradient
--   let (dwte, dwpe, dwqry, dwkey, dwval, dwout, dwup, dwdown, dwvoc) =
--     grad_loss dl p tokens mask
--   let dp = to_params dwte dwpe dwqry dwkey dwval dwout dwup dwdown dwvoc
--   -- cal new model weights
--   let (p', mp', vp') =
--     adam_opt p mp vp dp step n
--   in (p', mp', vp', loss)

-- entry train [n] (p : params) (mp : params) (vp : params)
--   (masks : [n][16][16]f64) (dls : [n]i64)
--   (seqs : [n][16]i64) =
--   let losses = imap1 n (\_ -> 0)
--   let (new_p, new_mp, new_vp, new_losses) =
--     loop (p', mp', vp', losses') = (p, mp, vp, losses)
--     for step < n do
--       let dl = dls[step]
--       let tokens = seqs[step]
--       let mask = masks[step]
--       let (p', mp', vp', loss) = (cal_step dl p' mp' vp' tokens mask step n)
--       let losses' = copy losses' with [step] = loss
--       in (p', mp', vp', losses')
--   in ((from_params new_p), (from_params new_mp), (from_params new_vp), new_losses)

entry zero_params : params =
  let wte = imap2 27 16 (\_ _ -> 0)
  let wpe = imap2 16 16 (\_ _ -> 0)
  let wqry = imap2 16 16 (\_ _ -> 0)
  let wkey = imap2 16 16 (\_ _ -> 0)
  let wval = imap2 16 16 (\_ _ -> 0)
  let wout = imap2 16 16 (\_ _ -> 0)
  let wup = imap2 64 16 (\_ _ -> 0)
  let wdown = imap2 16 64 (\_ _ -> 0)
  let wvoc = imap2 27 16 (\_ _ -> 0)
  in {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc}