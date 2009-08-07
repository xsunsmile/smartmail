
email = "孫コウ  mail+he_23432-adfa@question.com"
email += "孫コウ  mail+he_23432-adfa@question.com"
infos = email.gsub(/\r\n|\r|\n/,'[NL]').scan(/\+([a-z]*)_([\d]+-[a-z]+)@/)

str = "he_question_result"
p $1, $2, $3 if /(\w*)_(\w*)_(\w*)/ =~ str
