if diff $1 $2; then
  echo -e "\e[32mTest PASSED!\e[0m"
else
  echo -e "\e[31mTest FAILED!\e[0m"
fi