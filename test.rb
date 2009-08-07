
description = """
{sm_del:question}
下記の質問
ーーーーーーーーーー
{sm_get:question}
ーーーーーーーーーー
に対する答えです

{sm_get:answer}

"""
description2 = "sm_reply_to:cp"
# operation, operands = $1, $2 if /\{(sm_\w+):(.*)\}/ =~ description
results = description.scan(/\{(sm_\w+):(.*)\}/)
p results

# puts description2.gsub(/\{?(sm_\w+):(.*)\}?/,'result')
