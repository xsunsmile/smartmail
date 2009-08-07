require 'nkf'

class Iso2022jpMailer < ActionMailer::Base
  @@default_charset = 'iso-2022-jp'
  @@encode_subject  = false

  def base64(text, charset="iso-2022-jp", convert=true)
    if convert
      if charset == "iso-2022-jp"
        text = NKF.nkf('-j -m0', text)
      end
    end
    text = [text].pack('m').delete("¥r¥n")
    "=?#{charset}?B?#{text}?="
  end

  # 2) 本文を iso-2022-jp へ変換
  # どこでやればいいのか迷ったので、とりあえず create! に被せています
  def create! (*)
    super
    @mail.body = NKF::nkf('-j', @mail.body)
    return @mail   # メソッドチェインを期待した変更があったら怖いので
  end  

end
