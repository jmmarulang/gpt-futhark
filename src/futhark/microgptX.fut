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

let bs : i64 = 1
let sl : i64 = 16
let ed : i64 = 16
let ah : i64 = 4
let hd : i64 = 4
let fd : i64 = 64
let vo : i64 = 27

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

  def forward_seq :
       (mask: [16][16]real)
    -> (wp: [16][16]real)
    -> (wqry: [16][16]real)
    -> (wkey: [16][16]real)
    -> (wval: [16][16]real)
    -> (wo: [16][16]real)
    -> (wu: [64][16]real)
    -> (wd: [16][64]real)
    -> (wc: [27][16]real)
    -> (ws: [1][16][16]real)
    -> [1][16][27]real =
    #[unsafe]
    \(mask: [16][16]real) (wp: [16][16]real)
    (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
    (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
    (wc: [27][16]real) (ws: [1][16][16]real) ->

(let x0 = (imap1 1 (\i23 -> (imap2 16 16 (\i24 i25 -> (wp[i24][i25] F.+ ws[i23][i24][i25])))))
in (let x1 = (imap1 1 (\i26 -> (imap1 16 (\i27 -> (let x28 = (imap1 16 (\i32 -> (x0[i26][i27][i32] F.* x0[i26][i27][i32])))
in (let x29 = ((isum1 16 (\i33 -> x28[i33])) F./ fromi64 16)
in (let x30 = (F.sqrt (x29 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i31 -> (x0[i26][i27][i31] F.* (one F./ x30)))))))))))
in (let x2 = (imap1 1 (\i34 -> (imap1 16 (\i35 -> (let x36 = (imap1 16 (\i40 -> (x1[i34][i35][i40] F.* x1[i34][i35][i40])))
in (let x37 = ((isum1 16 (\i41 -> x36[i41])) F./ fromi64 16)
in (let x38 = (F.sqrt (x37 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i39 -> (x1[i34][i35][i39] F.* (one F./ x38)))))))))))
in (let x3 = (imap1 1 (\i42 -> (imap1 16 (\i43 -> (imap1 16 (\i44 -> (isum1 16 (\i45 -> (wqry[i44][i45] F.* x2[i42][i43][i45])))))))))
in (let x4 = (imap1 1 (\i46 -> (imap1 16 (\i47 -> (imap1 16 (\i48 -> (isum1 16 (\i49 -> (wkey[i48][i49] F.* x2[i46][i47][i49])))))))))
in (let x5 = (imap1 1 (\i50 -> (imap1 16 (\i51 -> (imap1 16 (\i52 -> (isum1 16 (\i53 -> (wval[i52][i53] F.* x2[i50][i51][i53])))))))))
in (let x6 = (imap1 1 (\i54 -> (imap1 16 (\i55 -> (imap1 4 (\i56 -> (imap1 4 (\i57 -> x3[i54][i55][((i56 * 4) + i57)]))))))))
in (let x7 = (imap1 1 (\i58 -> (imap1 16 (\i59 -> (imap1 4 (\i60 -> (imap1 4 (\i61 -> x4[i58][i59][((i60 * 4) + i61)]))))))))
in (let x8 = (imap1 1 (\i62 -> (imap1 16 (\i63 -> (imap1 4 (\i64 -> (imap1 4 (\i65 -> x5[i62][i63][((i64 * 4) + i65)]))))))))
in (let x9 = (imap1 1 (\i66 -> (imap1 4 (\i67 -> (imap1 16 (\i68 -> (imap1 4 (\i69 -> x6[i66][i68][i67][i69]))))))))
in (let x10 = (imap1 1 (\i70 -> (imap1 4 (\i71 -> (imap1 16 (\i72 -> (imap1 4 (\i73 -> x7[i70][i72][i71][i73]))))))))
in (let x11 = (imap1 1 (\i74 -> (imap1 4 (\i75 -> (imap1 16 (\i76 -> (imap1 4 (\i77 -> x8[i74][i76][i75][i77]))))))))
in (let x12 = (imap1 1 (\i78 -> (imap1 4 (\i79 -> (let x80 = (imap1 16 (\i82 -> (let x84 = (isoftmax1 16 (\i83 -> (((isum1 4 (\i86 -> (x9[i78][i79][i82][i86] F.* x10[i78][i79][i83][i86]))) F./ fromi64 2) F.+ mask[i82][i83])))
in (imap1 16 (\i85 -> x84[i85])))))
in (imap1 16 (\i81 -> (imap1 4 (\i88 -> (isum1 16 (\i89 -> (x80[i81][i89] F.* x11[i78][i79][i89][i88]))))))))))))
in (let x13 = (imap1 1 (\i90 -> (imap1 16 (\i91 -> (imap1 4 (\i92 -> (imap1 4 (\i93 -> x12[i90][i92][i91][i93]))))))))
in (let x14 = (imap1 1 (\i94 -> (imap1 16 (\i95 -> (imap1 16 (\i96 -> x13[i94][i95][(i96 / 4)][(i96 % 4)]))))))
in (let x15 = (imap1 1 (\i97 -> (imap1 16 (\i98 -> (imap1 16 (\i99 -> (isum1 16 (\i100 -> (wo[i99][i100] F.* x14[i97][i98][i100])))))))))
in (let x16 = (imap3 1 16 16 (\i101 i102 i103 -> (x1[i101][i102][i103] F.+ x15[i101][i102][i103])))
in (let x17 = (imap1 1 (\i104 -> (imap1 16 (\i105 -> (let x106 = (imap1 16 (\i110 -> (x16[i104][i105][i110] F.* x16[i104][i105][i110])))
in (let x107 = ((isum1 16 (\i111 -> x106[i111])) F./ fromi64 16)
in (let x108 = (F.sqrt (x107 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i109 -> (x16[i104][i105][i109] F.* (one F./ x108)))))))))))
in (let x18 = (imap1 1 (\i112 -> (imap1 16 (\i113 -> (imap1 64 (\i114 -> (isum1 16 (\i115 -> (wu[i114][i115] F.* x17[i112][i113][i115])))))))))
in (let x19 = (imap3 1 16 64 (\i116 i117 i118 -> (F.max x18[i116][i117][i118] zero)))
in (let x20 = (imap1 1 (\i119 -> (imap1 16 (\i120 -> (imap1 16 (\i121 -> (isum1 64 (\i122 -> (wd[i121][i122] F.* x19[i119][i120][i122])))))))))
in (let x21 = (imap3 1 16 16 (\i123 i124 i125 -> (x16[i123][i124][i125] F.+ x20[i123][i124][i125])))
in (imap1 1 (\i22 -> (imap1 16 (\i126 -> (imap1 27 (\i127 -> (isum1 16 (\i128 -> (wc[i127][i128] F.* x21[i22][i126][i128])))))))))))))))))))))))))))))))


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

(let x0 = (imap1 1 (\i25 -> (imap2 16 16 (\i26 i27 -> (wp[i26][i27] F.+ ws[i25][i26][i27])))))
in (let x1 = (imap1 1 (\i28 -> (imap1 16 (\i29 -> (let x30 = (imap1 16 (\i34 -> (x0[i28][i29][i34] F.* x0[i28][i29][i34])))
in (let x31 = ((isum1 16 (\i35 -> x30[i35])) F./ fromi64 16)
in (let x32 = (F.sqrt (x31 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i33 -> (x0[i28][i29][i33] F.* (one F./ x32)))))))))))
in (let x2 = (imap1 1 (\i36 -> (imap1 16 (\i37 -> (let x38 = (imap1 16 (\i42 -> (x1[i36][i37][i42] F.* x1[i36][i37][i42])))
in (let x39 = ((isum1 16 (\i43 -> x38[i43])) F./ fromi64 16)
in (let x40 = (F.sqrt (x39 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i41 -> (x1[i36][i37][i41] F.* (one F./ x40)))))))))))
in (let x3 = (imap1 1 (\i44 -> (imap1 16 (\i45 -> (imap1 16 (\i46 -> (isum1 16 (\i47 -> (wqry[i46][i47] F.* x2[i44][i45][i47])))))))))
in (let x4 = (imap1 1 (\i48 -> (imap1 16 (\i49 -> (imap1 16 (\i50 -> (isum1 16 (\i51 -> (wkey[i50][i51] F.* x2[i48][i49][i51])))))))))
in (let x5 = (imap1 1 (\i52 -> (imap1 16 (\i53 -> (imap1 16 (\i54 -> (isum1 16 (\i55 -> (wval[i54][i55] F.* x2[i52][i53][i55])))))))))
in (let x6 = (imap1 1 (\i56 -> (imap1 16 (\i57 -> (imap1 4 (\i58 -> (imap1 4 (\i59 -> x3[i56][i57][((i58 * 4) + i59)]))))))))
in (let x7 = (imap1 1 (\i60 -> (imap1 16 (\i61 -> (imap1 4 (\i62 -> (imap1 4 (\i63 -> x4[i60][i61][((i62 * 4) + i63)]))))))))
in (let x8 = (imap1 1 (\i64 -> (imap1 16 (\i65 -> (imap1 4 (\i66 -> (imap1 4 (\i67 -> x5[i64][i65][((i66 * 4) + i67)]))))))))
in (let x9 = (imap1 1 (\i68 -> (imap1 4 (\i69 -> (imap1 16 (\i70 -> (imap1 4 (\i71 -> x6[i68][i70][i69][i71]))))))))
in (let x10 = (imap1 1 (\i72 -> (imap1 4 (\i73 -> (imap1 16 (\i74 -> (imap1 4 (\i75 -> x7[i72][i74][i73][i75]))))))))
in (let x11 = (imap1 1 (\i76 -> (imap1 4 (\i77 -> (imap1 16 (\i78 -> (imap1 4 (\i79 -> x8[i76][i78][i77][i79]))))))))
in (let x12 = (imap1 1 (\i80 -> (imap1 4 (\i81 -> (let x82 = (imap1 16 (\i84 -> (let x86 = (isoftmax1 16 (\i85 -> (((isum1 4 (\i88 -> (x9[i80][i81][i84][i88] F.* x10[i80][i81][i85][i88]))) F./ fromi64 2) F.+ mask[i84][i85])))
in (imap1 16 (\i87 -> x86[i87])))))
in (imap1 16 (\i83 -> (imap1 4 (\i90 -> (isum1 16 (\i91 -> (x82[i83][i91] F.* x11[i80][i81][i91][i90]))))))))))))
in (let x13 = (imap1 1 (\i92 -> (imap1 16 (\i93 -> (imap1 4 (\i94 -> (imap1 4 (\i95 -> x12[i92][i94][i93][i95]))))))))
in (let x14 = (imap1 1 (\i96 -> (imap1 16 (\i97 -> (imap1 16 (\i98 -> x13[i96][i97][(i98 / 4)][(i98 % 4)]))))))
in (let x15 = (imap1 1 (\i99 -> (imap1 16 (\i100 -> (imap1 16 (\i101 -> (isum1 16 (\i102 -> (wo[i101][i102] F.* x14[i99][i100][i102])))))))))
in (let x16 = (imap3 1 16 16 (\i103 i104 i105 -> (x1[i103][i104][i105] F.+ x15[i103][i104][i105])))
in (let x17 = (imap1 1 (\i106 -> (imap1 16 (\i107 -> (let x108 = (imap1 16 (\i112 -> (x16[i106][i107][i112] F.* x16[i106][i107][i112])))
in (let x109 = ((isum1 16 (\i113 -> x108[i113])) F./ fromi64 16)
in (let x110 = (F.sqrt (x109 F.+ (one F./ fromi64 100000)))
in (imap1 16 (\i111 -> (x16[i106][i107][i111] F.* (one F./ x110)))))))))))
in (let x18 = (imap1 1 (\i114 -> (imap1 16 (\i115 -> (imap1 64 (\i116 -> (isum1 16 (\i117 -> (wu[i116][i117] F.* x17[i114][i115][i117])))))))))
in (let x19 = (imap3 1 16 64 (\i118 i119 i120 -> (F.max x18[i118][i119][i120] zero)))
in (let x20 = (let x121 = (imap1 1 (\i124 -> (imap1 16 (\i125 -> (imap1 16 (\i126 -> (isum1 64 (\i127 -> (wd[i126][i127] F.* x19[i124][i125][i127])))))))))
in (let x122 = (imap3 1 16 16 (\i128 i129 i130 -> (x16[i128][i129][i130] F.+ x121[i128][i129][i130])))
in (imap1 1 (\i123 -> (imap1 16 (\i131 -> (imap1 27 (\i132 -> (isum1 16 (\i133 -> (wc[i132][i133] F.* x122[i123][i131][i133])))))))))))
in (let x21 = (imap1 1 (\i134 -> (imap1 16 (\i135 -> (let x137 = (isoftmax1 27 (\i136 -> x20[i134][i135][i136]))
in (imap1 27 (\i138 -> x137[i138])))))))
in (let x22 = (imap1 1 (\i139 -> (imap1 16 (\i140 -> (F.neg (isum1 27 (\i141 -> ((F.log x21[i139][i140][i141]) F.* target[i139][i140][i141]))))))))
in ((isum2 1 16 (\i23 i24 -> x22[i23][i24])) F./ fromi64 16))))))))))))))))))))))))


}

module nn64 = nn f64

type params = {
  wte:   [vo][ed]f64, -- token embeddings
  wpe:   [sl][ed]f64, -- position embeddings
  wqry:  [ed][ed]f64, -- query weights
  wkey:  [ed][ed]f64, -- key weights
  wval:  [ed][ed]f64, -- value weights
  wout:  [ed][ed]f64, -- output weights
  wup:   [fd][ed]f64, -- MLP up-projection
  wdown: [ed][fd]f64, -- MLP down-projection
  wvoc:  [vo][ed]f64  -- output projection
}

entry to_params (wte: [vo][ed]f64)  (wpe: [sl][ed]f64)
    (wqry: [ed][ed]f64) (wkey: [ed][ed]f64) (wval: [ed][ed]f64)
    (wout: [ed][ed]f64) (wup: [fd][ed]f64) (wdown: [ed][fd]f64)
    (wvoc: [vo][ed]f64) : params =
    {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc}

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
  let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
  in (wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc)

entry forward (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
   let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
   let ws = (imap3 bs sl ed (\i j k -> wte[tokens[i][j]][k]))
   in (nn64.forward_seq
        (mask  :> [16][16]f64)
        (wpe   :> [16][16]f64)
        (wqry  :> [16][16]f64)
        (wkey  :> [16][16]f64)
        (wval  :> [16][16]f64)
        (wout  :> [16][16]f64)
        (wup   :> [64][16]f64)
        (wdown :> [16][64]f64)
        (wvoc  :> [27][16]f64)
        (ws    :> [1][16][16]f64)
               :> [bs][sl][vo]f64)

def cal_target (n : i64) (tokens : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (tokens[i][j + 1] == k)) then 1 else 0))

entry loss (dl : i64) (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : f64 =
   let {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc} = p
   let target = cal_target dl tokens
   let ws = (imap3 1 16 16 (\i j k -> wte[tokens[i][j]][k]))
   in (nn64.cal_loss
        (mask  :> [16][16]f64)
        (wpe   :> [16][16]f64)
        (wqry  :> [16][16]f64)
        (wkey  :> [16][16]f64)
        (wval  :> [16][16]f64)
        (wout  :> [16][16]f64)
        (wup   :> [64][16]f64)
        (wdown :> [16][64]f64)
        (wvoc  :> [27][16]f64)
        (ws    :> [1][16][16]f64)
        (target :> [1][16][27]f64)
               :> f64)
  --  in nn64.cal_loss mask wpe wqry wkey wval wout wup wdown wvoc ws target

entry zero_params : params =
  let wte = imap2 vo ed (\_ _ -> 0)
  let wpe = imap2 sl ed (\_ _ -> 0)
  let wqry = imap2 ed ed (\_ _ -> 0)
  let wkey = imap2 ed ed (\_ _ -> 0)
  let wval = imap2 ed ed (\_ _ -> 0)
  let wout = imap2 ed ed (\_ _ -> 0)
  let wup = imap2 fd ed (\_ _ -> 0)
  let wdown = imap2 ed fd (\_ _ -> 0)
  let wvoc = imap2 vo ed (\_ _ -> 0)
  in {wte, wpe, wqry, wkey, wval, wout, wup, wdown, wvoc}