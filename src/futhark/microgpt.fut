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
  -> (ws: [16][16]real)
  -> [16][27]real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [16][16]real) ->
  imap2 16 27 (\_ _ -> zero)

def cal_loss : (mask: [16][16]real)
  -> (wp: [16][16]real)
  -> (wqry: [16][16]real)
  -> (wkey: [16][16]real)
  -> (wval: [16][16]real)
  -> (wo: [16][16]real)
  -> (wu: [64][16]real)
  -> (wd: [16][64]real)
  -> (wc: [27][16]real)
  -> (ws: [16][16]real)
  -> (target: [16][27]real)
  -> real =
  #[unsafe]
  \(mask: [16][16]real) (wp: [16][16]real)
  (wqry: [16][16]real) (wkey: [16][16]real) (wval: [16][16]real)
  (wo: [16][16]real) (wu: [64][16]real) (wd: [16][64]real)
  (wc: [27][16]real) (ws: [16][16]real) (target: [16][27]real) ->
  zero


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

  (ws, wp, wqry, wkey, wval, wo, wu, wd, wc)
}

module nn64 = nn f64

-- let bs : i64 = bs
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

def forward_batch [bs] :
      (mask: [sl][sl]f64)
  -> (wp: [sl][ed]f64)
  -> (wqry: [ed][ed]f64)
  -> (wkey: [ed][ed]f64)
  -> (wval: [ed][ed]f64)
  -> (wo: [ed][ed]f64)
  -> (wu: [fd][ed]f64)
  -> (wd: [ed][fd]f64)
  -> (wc: [vo][ed]f64)
  -> (ws: [bs][sl][ed]f64)
  -> [bs][sl][vo]f64 =
  #[unsafe]
  \mask wp wqry wkey wval wo wu wd wc ws ->
  imap3 bs sl vo (\i j k ->
    (nn64.forward_seq
        (mask  :> [16][16]f64)
        (wp    :> [16][16]f64)
        (wqry  :> [16][16]f64)
        (wkey  :> [16][16]f64)
        (wval  :> [16][16]f64)
        (wo    :> [16][16]f64)
        (wu    :> [64][16]f64)
        (wd    :> [16][64]f64)
        (wc    :> [27][16]f64)
        (ws[i] :> [16][16]f64)
               :> [sl][vo]f64)[j][k])

entry forward [bs] (p : params) (tokens : [bs][sl]i64) (mask : [sl][sl]f64) : [bs][sl][vo]f64 =
   let {wt, wp, wqry, wkey, wval, wo, wu, wd, wc} = p
   let ws = (imap3 bs sl ed (\i j k -> wt[tokens[i][j]][k]))
   in forward_batch mask wp wqry wkey wval wo wu wd wc ws

entry cal_target [bs] (tokens : [bs][sl]i64) : [bs][sl]i64 =
  imap2 bs sl (\i j -> if (j < sl - 1) then tokens[i][j + 1] else vo)

entry cal_target_mask [bs] (n : i64) (target : [bs][sl]i64) : [bs][sl][vo]f64 =
  imap3 bs sl vo (\i j k -> (if ((j < (n - 1)) && (target[i][j] == k)) then 1 else 0))

def loss_batch [bs] :
      (mask: [sl][sl]f64)
  -> (wp: [sl][ed]f64)
  -> (wqry: [ed][ed]f64)
  -> (wkey: [ed][ed]f64)
  -> (wval: [ed][ed]f64)
  -> (wo: [ed][ed]f64)
  -> (wu: [fd][ed]f64)
  -> (wd: [ed][fd]f64)
  -> (wc: [vo][ed]f64)
  -> (ws: [bs][sl][ed]f64)
  -> (target: [bs][sl][vo]f64)
  -> [bs][sl][vo]f64 =
  #[unsafe]
  \mask wp wqry wkey wval wo wu wd wc ws target ->
  imap3 bs sl vo (\i j k ->
    (nn64.cal_loss
        (mask  :> [16][16]f64)
        (wp    :> [16][16]f64)
        (wqry  :> [16][16]f64)
        (wkey  :> [16][16]f64)
        (wval  :> [16][16]f64)
        (wo    :> [16][16]f64)
        (wu    :> [64][16]f64)
        (wd    :> [16][64]f64)
        (wc    :> [27][16]f64)
        (ws[i] :> [16][16]f64)
        (target[i] :> [16][27]f64)
               :> [sl][vo]f64)[j][k])

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
  (masks : [steps][sl][sl]f64) (dls  : [steps]i64)
  (batches  : [steps][bs][sl]i64) =
  let (new_p, new_mp, new_vp) =
    loop (p', mp', vp') = (p, mp, vp)
    for step < steps do
      let dl = dls[step]
      let batch = batches[step]
      let mask = masks[step]
      let (p', mp', vp') = (cal_step dl p' mp' vp' batch mask step steps)
      in (p', mp', vp')
  in ((from_params new_p), (from_params new_mp), (from_params new_vp))

-- def cal_step_verbose (dl : i64) (p : params) (mp : params) (vp : params)
--   (batch : [bs][sl]i64) (mask : [sl][sl]f64)
--   (step : i64) steps :
--   (params,  params,  params , f64) =
--   let loss = loss dl p batch mask
--   -- cal gradient
--   let (dwt, dwp, dwqry, dwkey, dwval, dwo, dwu, dwd, dwc) =
--     grad dl p batch mask
--   let dp = to_params dwt dwp dwqry dwkey dwval dwo dwu dwd dwc
--   -- cal new model weights
--   let (p', mp', vp') =
--     adam_opt p mp vp dp step steps
--   in (p', mp', vp', loss)

-- entry train_verbose [steps] (p : params) (mp : params) (vp : params)
--   (masks : [steps][sl][sl]f64) (dls  : [steps]i64)
--   (batches  : [steps][bs][sl]i64) =
--   let losses = imap1 steps (\_ -> 0)
--   let (new_p, new_mp, new_vp, new_losses) =
--     loop (p', mp', vp', losses') = (p, mp, vp, losses)
--     for step < steps do
--       let dl = dls[step]
--       let batch = batches[step]
--       let mask = masks[step]
--       let (p', mp', vp', loss) = (cal_step_verbose dl p' mp' vp' batch mask step steps)
--       let losses' = copy losses' with [step] = loss
--       in (p', mp', vp', losses')
--   in ((from_params new_p), (from_params new_mp), (from_params new_vp), new_losses)

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