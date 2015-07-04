#!/usr/bin/bash
diff $1 $2 | grep -E '^(<|>)' | sed 's:^< \(.*\):<del style="color\:red; text-decoration\: none">- \1</del><br>:' | sed 's:^> \(.*\):<ins style="color\:green; text-decoration\: none">+ \1</ins><br>:' > $3
