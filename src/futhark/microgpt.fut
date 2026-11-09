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

def forward_seq [bs] :
      (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [bs][16][16]real)
  -> [bs][16][27]real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [bs][16][16]real) ->

(let x0 = (imap1 bs (\i23 -> (imap2 16 16 (\i24 i25 -> (wp[i24][i25] F.+ ws[i23][i24][i25])))))
in (let x1 = (imap1 bs (\i26 -> (imap1 16 (\i27 -> (let x28 = (imap1 16 (\i32 -> (x0[i26][i27][i32] F.* x0[i26][i27][i32])))
in (let x29 = ((isum1 16 (\i33 -> x28[i33])) F./ fromi64 16)
in (let x30 = (F.sqrt (x29 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i31 -> (x0[i26][i27][i31] F.* (one F./ x30)))))))))))
in (let x2 = (imap1 bs (\i34 -> (imap1 16 (\i35 -> (let x36 = (imap1 16 (\i40 -> (x1[i34][i35][i40] F.* x1[i34][i35][i40])))
in (let x37 = ((isum1 16 (\i41 -> x36[i41])) F./ fromi64 16)
in (let x38 = (F.sqrt (x37 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i39 -> (x1[i34][i35][i39] F.* (one F./ x38)))))))))))
in (let x3 = (imap1 bs (\i42 -> (imap1 16 (\i43 -> (imap1 16 (\i44 -> (isum1 16 (\i45 -> (wqry[i44][i45] F.* x2[i42][i43][i45])))))))))
in (let x4 = (imap1 bs (\i46 -> (imap1 16 (\i47 -> (imap1 16 (\i48 -> (isum1 16 (\i49 -> (wkey[i48][i49] F.* x2[i46][i47][i49])))))))))
in (let x5 = (imap1 bs (\i50 -> (imap1 16 (\i51 -> (imap1 16 (\i52 -> (isum1 16 (\i53 -> (wval[i52][i53] F.* x2[i50][i51][i53])))))))))
in (let x6 = (imap1 bs (\i54 -> (imap1 16 (\i55 -> (imap1 4 (\i56 -> (imap1 4 (\i57 -> x3[i54][i55][((i56 * 4) + i57)]))))))))
in (let x7 = (imap1 bs (\i58 -> (imap1 16 (\i59 -> (imap1 4 (\i60 -> (imap1 4 (\i61 -> x4[i58][i59][((i60 * 4) + i61)]))))))))
in (let x8 = (imap1 bs (\i62 -> (imap1 16 (\i63 -> (imap1 4 (\i64 -> (imap1 4 (\i65 -> x5[i62][i63][((i64 * 4) + i65)]))))))))
in (let x9 = (imap1 bs (\i66 -> (imap1 4 (\i67 -> (imap1 16 (\i68 -> (imap1 4 (\i69 -> x6[i66][i68][i67][i69]))))))))
in (let x10 = (imap1 bs (\i70 -> (imap1 4 (\i71 -> (imap1 16 (\i72 -> (imap1 4 (\i73 -> x7[i70][i72][i71][i73]))))))))
in (let x11 = (imap1 bs (\i74 -> (imap1 4 (\i75 -> (imap1 16 (\i76 -> (imap1 4 (\i77 -> x8[i74][i76][i75][i77]))))))))
in (let x12 = (imap1 bs (\i78 -> (imap1 4 (\i79 -> (let x80 = (imap1 16 (\i82 -> (let x84 = (isoftmax1 16 (\i83 -> (((isum1 4 (\i86 -> (x9[i78][i79][i82][i86] F.* x10[i78][i79][i83][i86]))) F./ fromi64 2) F.+ mask[i82][i83])))
in (imap1 16 (\i85 -> x84[i85])))))
in (imap1 16 (\i81 -> (imap1 4 (\i88 -> (isum1 16 (\i89 -> (x80[i81][i89] F.* x11[i78][i79][i89][i88]))))))))))))
in (let x13 = (imap1 bs (\i90 -> (imap1 16 (\i91 -> (imap1 4 (\i92 -> (imap1 4 (\i93 -> x12[i90][i92][i91][i93]))))))))
in (let x14 = (imap1 bs (\i94 -> (imap1 16 (\i95 -> (imap1 16 (\i96 -> x13[i94][i95][(i96 / 4)][(i96 % 4)]))))))
in (let x15 = (imap1 bs (\i97 -> (imap1 16 (\i98 -> (imap1 16 (\i99 -> (isum1 16 (\i100 -> (wo[i99][i100] F.* x14[i97][i98][i100])))))))))
in (let x16 = (imap3 bs 16 16 (\i101 i102 i103 -> (x1[i101][i102][i103] F.+ x15[i101][i102][i103])))
in (let x17 = (imap1 bs (\i104 -> (imap1 16 (\i105 -> (let x106 = (imap1 16 (\i110 -> (x16[i104][i105][i110] F.* x16[i104][i105][i110])))
in (let x107 = ((isum1 16 (\i111 -> x106[i111])) F./ fromi64 16)
in (let x108 = (F.sqrt (x107 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i109 -> (x16[i104][i105][i109] F.* (one F./ x108)))))))))))
in (let x18 = (imap1 bs (\i112 -> (imap1 16 (\i113 -> (imap1 64 (\i114 -> (isum1 16 (\i115 -> (wu[i114][i115] F.* x17[i112][i113][i115])))))))))
in (let x19 = (imap3 bs 16 64 (\i116 i117 i118 -> (F.max x18[i116][i117][i118] zero)))
in (let x20 = (imap1 bs (\i119 -> (imap1 16 (\i120 -> (imap1 16 (\i121 -> (isum1 64 (\i122 -> (wd[i121][i122] F.* x19[i119][i120][i122])))))))))
in (let x21 = (imap3 bs 16 16 (\i123 i124 i125 -> (x16[i123][i124][i125] F.+ x20[i123][i124][i125])))
in (imap1 bs (\i22 -> (imap1 16 (\i126 -> (imap1 27 (\i127 -> (isum1 16 (\i128 -> (wc[i127][i128] F.* x21[i22][i126][i128])))))))))))))))))))))))))))))))

def cal_loss [bs] : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [bs][16][16]real)
  -> (target: [bs][16][27]real)
  -> real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [bs][16][16]real) (target: [bs][16][27]real) ->

(let x0 = (imap1 bs (\i25 -> (imap2 16 16 (\i26 i27 -> (wp[i26][i27] F.+ ws[i25][i26][i27])))))
in (let x1 = (imap1 bs (\i28 -> (imap1 16 (\i29 -> (let x30 = (imap1 16 (\i34 -> (x0[i28][i29][i34] F.* x0[i28][i29][i34])))
in (let x31 = ((isum1 16 (\i35 -> x30[i35])) F./ fromi64 16)
in (let x32 = (F.sqrt (x31 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i33 -> (x0[i28][i29][i33] F.* (one F./ x32)))))))))))
in (let x2 = (imap1 bs (\i36 -> (imap1 16 (\i37 -> (let x38 = (imap1 16 (\i42 -> (x1[i36][i37][i42] F.* x1[i36][i37][i42])))
in (let x39 = ((isum1 16 (\i43 -> x38[i43])) F./ fromi64 16)
in (let x40 = (F.sqrt (x39 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i41 -> (x1[i36][i37][i41] F.* (one F./ x40)))))))))))
in (let x3 = (imap1 bs (\i44 -> (imap1 16 (\i45 -> (imap1 16 (\i46 -> (isum1 16 (\i47 -> (wqry[i46][i47] F.* x2[i44][i45][i47])))))))))
in (let x4 = (imap1 bs (\i48 -> (imap1 16 (\i49 -> (imap1 16 (\i50 -> (isum1 16 (\i51 -> (wkey[i50][i51] F.* x2[i48][i49][i51])))))))))
in (let x5 = (imap1 bs (\i52 -> (imap1 16 (\i53 -> (imap1 16 (\i54 -> (isum1 16 (\i55 -> (wval[i54][i55] F.* x2[i52][i53][i55])))))))))
in (let x6 = (imap1 bs (\i56 -> (imap1 16 (\i57 -> (imap1 4 (\i58 -> (imap1 4 (\i59 -> x3[i56][i57][((i58 * 4) + i59)]))))))))
in (let x7 = (imap1 bs (\i60 -> (imap1 16 (\i61 -> (imap1 4 (\i62 -> (imap1 4 (\i63 -> x4[i60][i61][((i62 * 4) + i63)]))))))))
in (let x8 = (imap1 bs (\i64 -> (imap1 16 (\i65 -> (imap1 4 (\i66 -> (imap1 4 (\i67 -> x5[i64][i65][((i66 * 4) + i67)]))))))))
in (let x9 = (imap1 bs (\i68 -> (imap1 4 (\i69 -> (imap1 16 (\i70 -> (imap1 4 (\i71 -> x6[i68][i70][i69][i71]))))))))
in (let x10 = (imap1 bs (\i72 -> (imap1 4 (\i73 -> (imap1 16 (\i74 -> (imap1 4 (\i75 -> x7[i72][i74][i73][i75]))))))))
in (let x11 = (imap1 bs (\i76 -> (imap1 4 (\i77 -> (imap1 16 (\i78 -> (imap1 4 (\i79 -> x8[i76][i78][i77][i79]))))))))
in (let x12 = (imap1 bs (\i80 -> (imap1 4 (\i81 -> (let x82 = (imap1 16 (\i84 -> (let x86 = (isoftmax1 16 (\i85 -> (((isum1 4 (\i88 -> (x9[i80][i81][i84][i88] F.* x10[i80][i81][i85][i88]))) F./ fromi64 2) F.+ mask[i84][i85])))
in (imap1 16 (\i87 -> x86[i87])))))
in (imap1 16 (\i83 -> (imap1 4 (\i90 -> (isum1 16 (\i91 -> (x82[i83][i91] F.* x11[i80][i81][i91][i90]))))))))))))
in (let x13 = (imap1 bs (\i92 -> (imap1 16 (\i93 -> (imap1 4 (\i94 -> (imap1 4 (\i95 -> x12[i92][i94][i93][i95]))))))))
in (let x14 = (imap1 bs (\i96 -> (imap1 16 (\i97 -> (imap1 16 (\i98 -> x13[i96][i97][(i98 / 4)][(i98 % 4)]))))))
in (let x15 = (imap1 bs (\i99 -> (imap1 16 (\i100 -> (imap1 16 (\i101 -> (isum1 16 (\i102 -> (wo[i101][i102] F.* x14[i99][i100][i102])))))))))
in (let x16 = (imap3 bs 16 16 (\i103 i104 i105 -> (x1[i103][i104][i105] F.+ x15[i103][i104][i105])))
in (let x17 = (imap1 bs (\i106 -> (imap1 16 (\i107 -> (let x108 = (imap1 16 (\i112 -> (x16[i106][i107][i112] F.* x16[i106][i107][i112])))
in (let x109 = ((isum1 16 (\i113 -> x108[i113])) F./ fromi64 16)
in (let x110 = (F.sqrt (x109 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i111 -> (x16[i106][i107][i111] F.* (one F./ x110)))))))))))
in (let x18 = (imap1 bs (\i114 -> (imap1 16 (\i115 -> (imap1 64 (\i116 -> (isum1 16 (\i117 -> (wu[i116][i117] F.* x17[i114][i115][i117])))))))))
in (let x19 = (imap3 bs 16 64 (\i118 i119 i120 -> (F.max x18[i118][i119][i120] zero)))
in (let x20 = (let x121 = (imap1 bs (\i124 -> (imap1 16 (\i125 -> (imap1 16 (\i126 -> (isum1 64 (\i127 -> (wd[i126][i127] F.* x19[i124][i125][i127])))))))))
in (let x122 = (imap3 bs 16 16 (\i128 i129 i130 -> (x16[i128][i129][i130] F.+ x121[i128][i129][i130])))
in (imap1 bs (\i123 -> (imap1 16 (\i131 -> (imap1 27 (\i132 -> (isum1 16 (\i133 -> (wc[i132][i133] F.* x122[i123][i131][i133])))))))))))
in (let x21 = (imap3 bs 16 27 (\i134 i135 i136 -> (target[i134][i135][i136] F.* (F.neg (F.log (let x138 = (isoftmax1 27 (\i137 -> x20[i134][i135][i137]))
in x138[i136]))))))
in ((isum3 bs 16 27 (\i22 i23 i24 -> x21[i22][i23][i24])) F./ fromi64 (bs * 16))))))))))))))))))))))))


def grad [bs] : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [bs][16][16]real)
  -> (target: [bs][16][27]real)
  ->
  (
    [bs][16][16]real, --ws
    [16][16]real, -- position embeddings
    [16][16]real, -- query weights
    [16][16]real, -- key weights
    [16][16]real, -- value weights
    [16][16]real, -- output weights
    [64][16]real, -- MLP up-projection
    [16][64]real, -- MLP down-projection
    [27][16]real  -- output projection
  ) =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [bs][16][16]real) (target: [bs][16][27]real) ->

let t0 = (let x0 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (wp[i1][i2] F.+ ws[i0][i1][i2])))))))
in (let x1 = (imap1 bs (\i1 -> (imap1 16 (\i2 -> (let x3 = ((isum1 16 (\i3 -> (x0[i1][i2][i3] F.* x0[i1][i2][i3]))) F./ fromi64 16)
in (let x4 = (F.sqrt (x3 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i5 -> (x0[i1][i2][i5] F.* (one F./ x4))))))))))
in (let x2 = (imap1 bs (\i2 -> (imap1 16 (\i3 -> (let x4 = ((isum1 16 (\i4 -> (x1[i2][i3][i4] F.* x1[i2][i3][i4]))) F./ fromi64 16)
in (let x5 = (F.sqrt (x4 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i6 -> (x1[i2][i3][i6] F.* (one F./ x5))))))))))
in (let x3 = (imap1 bs (\i3 -> (imap1 16 (\i4 -> (imap1 16 (\i5 -> (isum1 16 (\i6 -> (wqry[i5][i6] F.* x2[i3][i4][i6])))))))))
in (let x4 = (imap1 bs (\i4 -> (imap1 16 (\i5 -> (imap1 16 (\i6 -> (isum1 16 (\i7 -> (wkey[i6][i7] F.* x2[i4][i5][i7])))))))))
in (let x5 = (imap1 bs (\i5 -> (imap1 16 (\i6 -> (imap1 16 (\i7 -> (isum1 16 (\i8 -> (wval[i7][i8] F.* x2[i5][i6][i8])))))))))
in (let x6 = (imap1 bs (\i6 -> (imap1 16 (\i7 -> (imap1 4 (\i8 -> (imap1 4 (\i9 -> x3[i6][i7][((i8 * 4) + i9)]))))))))
in (let x7 = (imap1 bs (\i7 -> (imap1 16 (\i8 -> (imap1 4 (\i9 -> (imap1 4 (\i10 -> x4[i7][i8][((i9 * 4) + i10)]))))))))
in (let x8 = (imap1 bs (\i8 -> (imap1 16 (\i9 -> (imap1 4 (\i10 -> (imap1 4 (\i11 -> x5[i8][i9][((i10 * 4) + i11)]))))))))
in (let x9 = (imap1 bs (\i9 -> (imap1 4 (\i10 -> (imap1 16 (\i11 -> (imap1 4 (\i12 -> x6[i9][i11][i10][i12]))))))))
in (let x10 = (imap1 bs (\i10 -> (imap1 4 (\i11 -> (imap1 16 (\i12 -> (imap1 4 (\i13 -> x7[i10][i12][i11][i13]))))))))
in (let x11 = (imap1 bs (\i11 -> (imap1 4 (\i12 -> (imap1 16 (\i13 -> (imap1 4 (\i14 -> x8[i11][i13][i12][i14]))))))))
in (let x12 = (imap1 bs (\i12 -> (imap1 4 (\i13 -> (let x14 = (imap1 16 (\i14 -> (let x15 = (isoftmax1 16 (\i15 -> (((isum1 4 (\i16 -> (x9[i12][i13][i14][i16] F.* x10[i12][i13][i15][i16]))) F./ fromi64 2) F.+ mask[i14][i15])))
in (imap1 16 (\i16 -> x15[i16])))))
in (imap1 16 (\i15 -> (imap1 4 (\i16 -> (isum1 16 (\i17 -> (x14[i15][i17] F.* x11[i12][i13][i17][i16]))))))))))))
in (let x13 = (imap1 bs (\i13 -> (imap1 16 (\i14 -> (imap1 4 (\i15 -> (imap1 4 (\i16 -> x12[i13][i15][i14][i16]))))))))
in (let x14 = (imap1 bs (\i14 -> (imap1 16 (\i15 -> (imap1 16 (\i16 -> x13[i14][i15][(i16 / 4)][(i16 % 4)]))))))
in (let x15 = (imap1 bs (\i15 -> (imap1 16 (\i16 -> (imap1 16 (\i17 -> (isum1 16 (\i18 -> (wo[i17][i18] F.* x14[i15][i16][i18])))))))))
in (let x16 = (imap1 bs (\i16 -> (imap1 16 (\i17 -> (imap1 16 (\i18 -> (x1[i16][i17][i18] F.+ x15[i16][i17][i18])))))))
in (let x17 = (imap1 bs (\i17 -> (imap1 16 (\i18 -> (let x19 = ((isum1 16 (\i19 -> (x16[i17][i18][i19] F.* x16[i17][i18][i19]))) F./ fromi64 16)
in (let x20 = (F.sqrt (x19 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i21 -> (x16[i17][i18][i21] F.* (one F./ x20))))))))))
in (let x18 = (imap1 bs (\i18 -> (imap1 16 (\i19 -> (imap1 64 (\i20 -> (isum1 16 (\i21 -> (wu[i20][i21] F.* x17[i18][i19][i21])))))))))
in (let x19 = (imap1 bs (\i19 -> (imap1 16 (\i20 -> (imap1 64 (\i21 -> (F.max x18[i19][i20][i21] zero)))))))
in (let x20 = (imap1 bs (\i20 -> (imap1 16 (\i21 -> (imap1 16 (\i22 -> (isum1 64 (\i23 -> (wd[i22][i23] F.* x19[i20][i21][i23])))))))))
in (let x21 = (imap1 bs (\i21 -> (imap1 16 (\i22 -> (imap1 16 (\i23 -> (x16[i21][i22][i23] F.+ x20[i21][i22][i23])))))))
in (imap1 bs (\i22 -> (imap1 16 (\i23 -> (imap1 27 (\i24 -> (isum1 16 (\i25 -> (wc[i24][i25] F.* x21[i22][i23][i25])))))))))))))))))))))))))))))))
let t1 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 27 (\i2 -> (one F./ fromi64 (16 * bs))))))))
let t2 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (let x2 = (isoftmax1 27 (\i2 -> t0[i0][i1][i2]))
in (imap1 27 (\i3 -> x2[i3])))))))
let t3 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (let x2 = (isoftmax1 27 (\i2 -> t0[i0][i1][i2]))
in (imap1 27 (\i3 -> (F.neg ((target[i0][i1][i3] F.* t1[i0][i1][i3]) F.* (one F./ x2[i3]))))))))))
let t4 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (isum1 27 (\i2 -> (t3[i0][i1][i2] F.* t2[i0][i1][i2])))))))
let t5 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 27 (\i2 -> (t2[i0][i1][i2] F.* (t3[i0][i1][i2] F.+ (F.neg t4[i0][i1])))))))))
let t6 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (wp[i1][i2] F.+ ws[i0][i1][i2])))))))
let t7 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (let x2 = ((isum1 16 (\i2 -> (t6[i0][i1][i2] F.* t6[i0][i1][i2]))) F./ fromi64 16)
in (let x3 = (F.sqrt (x2 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i4 -> (t6[i0][i1][i4] F.* (one F./ x3))))))))))
let t8 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (let x2 = ((isum1 16 (\i2 -> (t7[i0][i1][i2] F.* t7[i0][i1][i2]))) F./ fromi64 16)
in (let x3 = (F.sqrt (x2 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i4 -> (t7[i0][i1][i4] F.* (one F./ x3))))))))))
let t9 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 16 (\i3 -> (wqry[i2][i3] F.* t8[i0][i1][i3])))))))))
let t10 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 16 (\i3 -> (wkey[i2][i3] F.* t8[i0][i1][i3])))))))))
let t11 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 16 (\i3 -> (wval[i2][i3] F.* t8[i0][i1][i3])))))))))
let t12 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t9[i0][i1][((i2 * 4) + i3)]))))))))
let t13 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t10[i0][i1][((i2 * 4) + i3)]))))))))
let t14 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t11[i0][i1][((i2 * 4) + i3)]))))))))
let t15 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> t12[i0][i2][i1][i3]))))))))
let t16 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> t13[i0][i2][i1][i3]))))))))
let t17 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> t14[i0][i2][i1][i3]))))))))
let t18 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (let x2 = (imap1 16 (\i2 -> (let x3 = (isoftmax1 16 (\i3 -> (((isum1 4 (\i4 -> (t15[i0][i1][i2][i4] F.* t16[i0][i1][i3][i4]))) F./ fromi64 2) F.+ mask[i2][i3])))
in (imap1 16 (\i4 -> x3[i4])))))
in (imap1 16 (\i3 -> (imap1 4 (\i4 -> (isum1 16 (\i5 -> (x2[i3][i5] F.* t17[i0][i1][i5][i4]))))))))))))
let t19 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t18[i0][i2][i1][i3]))))))))
let t20 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> t19[i0][i1][(i2 / 4)][(i2 % 4)]))))))
let t21 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 16 (\i3 -> (wo[i2][i3] F.* t20[i0][i1][i3])))))))))
let t22 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t7[i0][i1][i2] F.+ t21[i0][i1][i2])))))))
let t23 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (let x2 = ((isum1 16 (\i2 -> (t22[i0][i1][i2] F.* t22[i0][i1][i2]))) F./ fromi64 16)
in (let x3 = (F.sqrt (x2 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i4 -> (t22[i0][i1][i4] F.* (one F./ x3))))))))))
let t24 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 64 (\i2 -> (isum1 16 (\i3 -> (wu[i2][i3] F.* t23[i0][i1][i3])))))))))
let t25 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 64 (\i2 -> (F.max t24[i0][i1][i2] zero)))))))
let t26 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 64 (\i3 -> (wd[i2][i3] F.* t25[i0][i1][i3])))))))))
let t27 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t22[i0][i1][i2] F.+ t26[i0][i1][i2])))))))
let t28 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 27 (\i3 -> (wc[i3][i2] F.* t5[i0][i1][i3])))))))))
let t29 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 64 (\i2 -> (isum1 16 (\i3 -> (wd[i3][i2] F.* t28[i0][i1][i3])))))))))
let t30 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 64 (\i2 -> ((indicatorp t24[i0][i1][i2]) F.* t29[i0][i1][i2])))))))
let t31 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 64 (\i3 -> (wu[i3][i2] F.* t30[i0][i1][i3])))))))))
let t32 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t22[i0][i1][i2] F.* t22[i0][i1][i2])))))))
let t33 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> ((isum1 16 (\i2 -> t32[i0][i1][i2])) F./ fromi64 16)))))
let t34 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (F.sqrt (t33[i0][i1] F.+ (one F./ fromi64 100000)))))))
let t35 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (F.neg ((one F./ t34[i0][i1]) F.* ((isum1 16 (\i2 -> (t22[i0][i1][i2] F.* t31[i0][i1][i2]))) F.* (one F./ t34[i0][i1]))))))))
let t36 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (t35[i0][i1] F.* (one F./ ((one F.+ one) F.* (F.sqrt (t33[i0][i1] F.+ (one F./ fromi64 100000))))))))))
let t37 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t36[i0][i1] F./ fromi64 16)))))))
let t38 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t28[i0][i1][i2] F.+ (((t31[i0][i1][i2] F.* (one F./ t34[i0][i1])) F.+ (t22[i0][i1][i2] F.* t37[i0][i1][i2])) F.+ (t37[i0][i1][i2] F.* t22[i0][i1][i2])))))))))
let t39 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (isum1 16 (\i3 -> (wo[i3][i2] F.* t38[i0][i1][i3])))))))))
let t40 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t39[i0][i1][((i2 * 4) + i3)]))))))))
let t41 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> t40[i0][i2][i1][i3]))))))))
let t42 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (let x3 = (isoftmax1 16 (\i3 -> (((isum1 4 (\i4 -> (t15[i0][i1][i2][i4] F.* t16[i0][i1][i3][i4]))) F./ fromi64 2) F.+ mask[i2][i3])))
in (imap1 16 (\i4 -> x3[i4])))))))))
let t43 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 16 (\i3 -> (isum1 4 (\i4 -> (t41[i0][i1][i2][i4] F.* t17[i0][i1][i3][i4])))))))))))
let t44 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 16 (\i3 -> t43[i0][i1][i2][i3]))))))))
let t45 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (isum1 16 (\i3 -> (t44[i0][i1][i2][i3] F.* t42[i0][i1][i2][i3])))))))))
let t46 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> (isum1 16 (\i4 -> (t42[i0][i1][i4][i2] F.* t41[i0][i1][i4][i3])))))))))))
let t47 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> (isum1 16 (\i4 -> (t15[i0][i1][i4][i3] F.* ((t42[i0][i1][i4][i2] F.* (t44[i0][i1][i4][i2] F.+ (F.neg t45[i0][i1][i4]))) F./ fromi64 2))))))))))))
let t48 = (imap1 bs (\i0 -> (imap1 4 (\i1 -> (imap1 16 (\i2 -> (imap1 4 (\i3 -> (isum1 16 (\i4 -> (((t42[i0][i1][i2][i4] F.* (t44[i0][i1][i2][i4] F.+ (F.neg t45[i0][i1][i2]))) F./ fromi64 2) F.* t16[i0][i1][i4][i3])))))))))))
let t49 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t46[i0][i2][i1][i3]))))))))
let t50 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t47[i0][i2][i1][i3]))))))))
let t51 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 4 (\i2 -> (imap1 4 (\i3 -> t48[i0][i2][i1][i3]))))))))
let t52 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> t49[i0][i1][(i2 / 4)][(i2 % 4)]))))))
let t53 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> t50[i0][i1][(i2 / 4)][(i2 % 4)]))))))
let t54 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> t51[i0][i1][(i2 / 4)][(i2 % 4)]))))))
let t55 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (((isum1 16 (\i3 -> (wval[i3][i2] F.* t52[i0][i1][i3]))) F.+ (isum1 16 (\i3 -> (wkey[i3][i2] F.* t53[i0][i1][i3])))) F.+ (isum1 16 (\i3 -> (wqry[i3][i2] F.* t54[i0][i1][i3]))))))))))
let t56 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t7[i0][i1][i2] F.* t7[i0][i1][i2])))))))
let t57 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> ((isum1 16 (\i2 -> t56[i0][i1][i2])) F./ fromi64 16)))))
let t58 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (F.sqrt (t57[i0][i1] F.+ (one F./ fromi64 100000)))))))
let t59 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (F.neg ((one F./ t58[i0][i1]) F.* ((isum1 16 (\i2 -> (t7[i0][i1][i2] F.* t55[i0][i1][i2]))) F.* (one F./ t58[i0][i1]))))))))
let t60 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (t59[i0][i1] F.* (one F./ ((one F.+ one) F.* (F.sqrt (t57[i0][i1] F.+ (one F./ fromi64 100000))))))))))
let t61 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t60[i0][i1] F./ fromi64 16)))))))
let t62 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t38[i0][i1][i2] F.+ (((t55[i0][i1][i2] F.* (one F./ t58[i0][i1])) F.+ (t7[i0][i1][i2] F.* t61[i0][i1][i2])) F.+ (t61[i0][i1][i2] F.* t7[i0][i1][i2])))))))))
let t63 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t6[i0][i1][i2] F.* t6[i0][i1][i2])))))))
let t64 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> ((isum1 16 (\i2 -> t63[i0][i1][i2])) F./ fromi64 16)))))
let t65 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (F.sqrt (t64[i0][i1] F.+ (one F./ fromi64 100000)))))))
let t66 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (F.neg ((one F./ t65[i0][i1]) F.* ((isum1 16 (\i2 -> (t6[i0][i1][i2] F.* t62[i0][i1][i2]))) F.* (one F./ t65[i0][i1]))))))))
let t67 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (t66[i0][i1] F.* (one F./ ((one F.+ one) F.* (F.sqrt (t64[i0][i1] F.+ (one F./ fromi64 100000))))))))))
let t68 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (t67[i0][i1] F./ fromi64 16)))))))
let t69 = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> (((t62[i0][i1][i2] F.* (one F./ t65[i0][i1])) F.+ (t6[i0][i1][i2] F.* t68[i0][i1][i2])) F.+ (t68[i0][i1][i2] F.* t6[i0][i1][i2]))))))))

let dwp = (imap1 16 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> t69[i2][i0][i1]))))))
let dwkey = (imap1 16 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t53[i2][i3][i0] F.* t8[i2][i3][i1])))))))))
let dwqry = (imap1 16 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t54[i2][i3][i0] F.* t8[i2][i3][i1])))))))))
let dwval = (imap1 16 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t52[i2][i3][i0] F.* t8[i2][i3][i1])))))))))
let dwo = (imap1 16 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t38[i2][i3][i0] F.* t20[i2][i3][i1])))))))))
-- let dmask = (imap1 16 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 4 (\i3 -> (t42[i2][i3][i0][i1] F.* (t44[i2][i3][i0][i1] F.+ (F.neg t45[i2][i3][i0])))))))))))
let dwu = (imap1 64 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t30[i2][i3][i0] F.* t23[i2][i3][i1])))))))))
let dwd = (imap1 16 (\i0 -> (imap1 64 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t28[i2][i3][i0] F.* t25[i2][i3][i1])))))))))
let dwc = (imap1 27 (\i0 -> (imap1 16 (\i1 -> (isum1 bs (\i2 -> (isum1 16 (\i3 -> (t5[i2][i3][i0] F.* t27[i2][i3][i1])))))))))
let dws = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (imap1 16 (\i2 -> t69[i0][i1][i2]))))))
-- let dtarget = (imap1 bs (\i0 -> (imap1 16 (\i1 -> (let x2 = (isoftmax1 27 (\i2 -> t0[i0][i1][i2]))
-- in (imap1 27 (\i3 -> (t1[i0][i1][i3] F.* (F.neg (F.log x2[i3]))))))))))

in (dws, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc)
}

module nn64 = nn f64

let sl : i64 = 16
let ed : i64 = 16
let ah : i64 = 4
let hd : i64 = 4
let fd : i64 = 64
let vo : i64 = 27

type params = {
  wt:   [vo][ed]f64, -- token embeddings
  wp:   [sl][ed]f64, -- position embeddings
  wqry:  [ed][ed]f64, -- query weights
  wkey:  [ed][ed]f64, -- key weights
  wval:  [ed][ed]f64, -- value weights
  wo:  [ed][ed]f64, -- output weights
  wu:   [fd][ed]f64, -- MLP up-projection
  wd: [ed][fd]f64, -- MLP down-projection
  wc:  [vo][ed]f64  -- output projection
}

entry to_params (wt: [vo][ed]f64)  (wp: [sl][ed]f64)
    (wqry: [ed][ed]f64) (wkey: [ed][ed]f64) (wval: [ed][ed]f64)
    (wo: [ed][ed]f64) (wu: [fd][ed]f64) (wd: [ed][fd]f64)
    (wc: [vo][ed]f64) : params =
    {wt, wp, wqry, wkey, wval, wo, wu, wd, wc}

def from_params (p : params) :
  (
  [vo][ed]f64, -- token embeddings
  [sl][ed]f64, -- position embeddings
  [ed][ed]f64, -- query weights
  [ed][ed]f64, -- key weights
  [ed][ed]f64, -- value weights
  [ed][ed]f64, -- output weights
  [fd][ed]f64, -- MLP up-projection
  [ed][fd]f64, -- MLP down-projection
  [vo][ed]f64  -- output projection
  ) =
  let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
  in (wt, wp, wqry, wkey, wval, wo, wu, wd, wc)

entry forward [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.forward_seq
        (mask :> [16][16]f64)
        (wp   :> [16][16]f64)
        (wqry :> [16][16]f64)
        (wkey :> [16][16]f64)
        (wval :> [16][16]f64)
        (wo   :> [16][16]f64)
        (wu   :> [64][16]f64)
        (wd   :> [16][64]f64)
        (wc   :> [27][16]f64)
        (ws   :> [bs][16][16]f64)
              :> [bs][sl][vo]f64)

entry cal_target [bs] (tokens : [bs][sl]i64) : [bs][sl]i64 =
  imap2 bs sl (\i j -> if (j < sl - 1) then tokens[i][j + 1] else vo)

entry cal_target_mask [bs] (n : i64) (target : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (target[i][j] == k)) then 1 else 0))

entry loss [bs] (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : f64 =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   let target = cal_target_mask dl (cal_target tokens)
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in (nn64.cal_loss
        (mask   :> [16][16]f64)
        (wp     :> [16][16]f64)
        (wqry   :> [16][16]f64)
        (wkey   :> [16][16]f64)
        (wval   :> [16][16]f64)
        (wo     :> [16][16]f64)
        (wu     :> [64][16]f64)
        (wd     :> [16][64]f64)
        (wc     :> [27][16]f64)
        (ws     :> [bs][16][16]f64)
        (target :> [bs][16][27]f64)
                :> f64)

def grad [bs] (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) :
        (
        [vo][ed]f64, --token embedding
        [sl][ed]f64, -- position embeddings
        [ed][ed]f64, -- query weights
        [ed][ed]f64, -- key weights
        [ed][ed]f64, -- value weights
        [ed][ed]f64, -- output weights
        [fd][ed]f64, -- MLP up-projection
        [ed][fd]f64, -- MLP down-projection
        [vo][ed]f64  -- output projection
        ) =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   -- cal targets
   let target = cal_target_mask dl (cal_target tokens)
   -- cal voc embedding
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   -- cal gradient
   let (dws, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc) =
    (nn64.grad
        (mask   :> [16][16]f64)
        (wp     :> [16][16]f64)
        (wqry   :> [16][16]f64)
        (wkey   :> [16][16]f64)
        (wval   :> [16][16]f64)
        (wo     :> [16][16]f64)
        (wu     :> [64][16]f64)
        (wd     :> [16][64]f64)
        (wc     :> [27][16]f64)
        (ws     :> [bs][16][16]f64)
        (target :> [bs][16][27]f64)
                :>
        (
        [bs][sl][ed]f64, --ws
        [sl][ed]f64, -- position embeddings
        [ed][ed]f64, -- query weights
        [ed][ed]f64, -- key weights
        [ed][ed]f64, -- value weights
        [ed][ed]f64, -- output weights
        [fd][ed]f64, -- MLP up-projection
        [ed][fd]f64, -- MLP down-projection
        [vo][ed]f64  -- output projection
        ))
   let dwt = (imap2 vo ed (\m n -> nn64.isum2 bs sl (\i k -> if (tokens[i][k] == m) then dws[i][k][n] else 0)))
   in  (dwt, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc)

def adam_opt2 [n] [m] (w : [n][m]f64) (mw : [n][m]f64) (vw : [n][m]f64)
  (dw : [n][m]f64) (step : i64) (lt_r : f64):
  ([n][m]f64, [n][m]f64, [n][m]f64) =
  let new_mw = imap2 n m (\i j ->
    0.85 * mw[i][j] + ((1 - 0.85) * dw[i][j]))
  let new_vw = imap2 n m (\i j ->
    0.99 * vw[i][j] + ((1 - 0.99) * dw[i][j] * dw[i][j]))
  let m_hat = imap2 n m (\i j ->
    new_mw[i][j] / (1 - 0.85 ** ((nn64.fromi64 step) + 1)))
  let v_hat = imap2 n m (\i j ->
    new_vw[i][j] / (1 - (0.99 ** ((nn64.fromi64 step) + 1))))
  let new_w = imap2 n m (\i j ->
    w[i][j] - (lt_r * m_hat[i][j] / ((v_hat[i][j] ** 0.5) + 0.00000001)))
  in (new_w, new_mw, new_vw)

def adam_opt (p : params) (mp : params) (vp : params)
  (dp : params) (step : i64) steps :
  (params,  params,  params) =
  let lt_r = 0.01 * (1 - (nn64.fromi64 step) / (nn64.fromi64 steps))
  let (wt, mwt, vwt) =
    adam_opt2 p.wt mp.wt vp.wt dp.wt step lt_r
  let (wp, mwp, vwp) =
    adam_opt2 p.wp mp.wp vp.wp dp.wp step lt_r
  let (wqry, mwqry, vwqry) =
    adam_opt2 p.wqry mp.wqry vp.wqry dp.wqry step lt_r
  let (wkey, mwkey, vwkey) =
    adam_opt2 p.wkey mp.wkey vp.wkey dp.wkey step lt_r
  let (wval, mwval, vwval) =
    adam_opt2 p.wval mp.wval vp.wval dp.wval step lt_r
  let (wo, mwo, vwo) =
    adam_opt2 p.wo mp.wo vp.wo dp.wo step lt_r
  let (wu, mwu, vwu) =
    adam_opt2 p.wu mp.wu vp.wu dp.wu step lt_r
  let (wd, mwd, vwd) =
    adam_opt2 p.wd mp.wd vp.wd dp.wd step lt_r
  let (wc, mwc, vwc) =
    adam_opt2 p.wc mp.wc vp.wc dp.wc step lt_r
  let p' = to_params wt wp wqry wkey wval wo wu wd wc
  let mp' = to_params mwt mwp mwqry mwkey mwval mwo mwu mwd mwc
  let vp' = to_params vwt vwp vwqry vwkey vwval vwo vwu vwd vwc
  in (p', mp', vp')

def cal_step [bs] (dl : i64) (p : params) (mp : params) (vp : params)
  (batch : [bs][sl]i64) (mask : [sl][sl]f64)
  (step : i64) steps :
  (params,  params,  params) =
  -- cal gradient
  let (dwt, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc) =
    grad dl p batch mask
  let dp = to_params dwt dwp dwqry dwkey dwval dwo dwu dwd dwc
  -- cal new model weights
  let (p', mp', vp') =
    adam_opt p mp vp dp step steps
  in (p', mp', vp')

entry train [bs] [steps] (p : params) (mp : params) (vp : params)
  (mask : [sl][sl]f64)
  (batches  : [steps][bs][sl]i64) =
  let (new_p, new_mp, new_vp) =
    loop (p', mp', vp') = (p, mp, vp)
    for step < steps do
      let batch = batches[step]
      let (p', mp', vp') = (cal_step sl p' mp' vp' batch mask step steps)
      in (p', mp', vp')
  in ((from_params new_p), (from_params new_mp), (from_params new_vp))

entry zero_params : params =
  let wt = imap2 vo ed (\_ _ -> 0)
  let wp = imap2 sl ed (\_ _ -> 0)
  let wqry = imap2 ed ed (\_ _ -> 0)
  let wkey = imap2 ed ed (\_ _ -> 0)
  let wval = imap2 ed ed (\_ _ -> 0)
  let wo = imap2 ed ed (\_ _ -> 0)
  let wu = imap2 fd ed (\_ _ -> 0)
  let wd = imap2 ed fd (\_ _ -> 0)
  let wc = imap2 vo ed (\_ _ -> 0)
  in {wt, wp, wqry, wkey, wval, wo, wu, wd, wc}