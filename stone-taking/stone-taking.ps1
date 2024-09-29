function stonetaking {
    write-host "＊＊＊＊＊＊＊＊"
    write-host "＊石取りゲーム＊"
    write-host "＊＊＊＊＊＊＊＊"
    write-host ""
    write-host "ルール"
    write-host "一列に並べられた20個の石があります。この石を先行後攻で交互に1～3個づつ取り"
    write-host "最後の1個を取った方が負けのゲームです"
    write-host ""
    write-host ""



    $stone = "○●○●○●○●○●○●○●○●○●○●"

    $trun = -1 #0:コンピュータが先手 1:人が先手 -1:未定
    $cnt=0
    $flg=$True


    while($trun -lt 0 -or $trun -gt 1) {
        write-host ""
        $trun = read-host "先手後手どちらにしますか(1:先手　0:後手)"
        if($trun.Length -ne 1) {
            $trun = -1
        } elseif(($trun.Length -ne 1) -or ([int]::TryParse($trun,[ref]$null) -eq $False)) {
            $trun = -1
        }
    }
    if($trun -eq 1){
        write-host "あなたが先手です"
    } else {
        write-host "あなたが後手です"
    }

    write-host ""

    function compturn {
        $resnum = 0
        #残りが奇数になるように取る
        if($stone.Length -eq 1){
            $resnum = 1
        } elseif($stone.Length -eq 4){
            $resnum = 3
        } else {
            if($stone.Length % 2 -eq 0){ #現在が偶数
                $resnum = 1
            } else { #現在が奇数
                $resnum = 2            
            }
        }

        return $resnum
    }

    function hantei($num){
        $res_stone = $stone
        for($i=0;$i -lt $num;$i++){
            $res_stone = $res_stone.Remove(0,1)
            if($res_stone.Length -eq 0){
                return $res_stone
            }
        }
        return $res_stone
    }

    write-host $stone

    while($flg){
        $tack_stone=""
        if($trun -eq 0){
            $takecnt = compturn
            $stone = hantei($takecnt)
            write-host "comの番 $takecnt 個取りました"
            write-host "$stone"
            if($stone.Length -eq 0){
                write-host "comの負けです"
                $flg = $False
            }
            $trun = 1 - $trun
        } else {
            $takecnt = -1
            while($takecnt -le 0 -or $takecnt -gt 3){
                write-host "あなたの番です"
                $takecnt = read-host "何個取りますか(1-3)"
                if($takecnt.Length -ne 1) {
                    $takecnt = -1
                } elseif(($takecnt.Length -ne 1) -or ([int]::TryParse($takecnt,[ref]$null) -eq $False)) {
                    $takecnt = -1
                }
            }
            write-host " $takecnt 個取りました"
            $stone = hantei($takecnt)
            write-host "$stone"
            if($stone.Length -eq 0){
                write-host "あなたの負けです"
                $flg = $False
            }
            $trun = 1 - $trun
        }

        write-host ""

    }
}
