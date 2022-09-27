upload-coverage: coverage/codeclimate.json
	cc-test-reporter upload-coverage -i $<

coverage/codeclimate.json: coverage/go.lcov .codeclimate.yml
	cc-test-reporter format-coverage -t lcov -o $@ $<

coverage/go.lcov: coverage/go.out
	$(info generating $@)
	@mkdir -p $(dir $@)
	@gcov2lcov -infile=$< -outfile=$@
