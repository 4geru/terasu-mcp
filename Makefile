.PHONY: restart start stop dev

restart:
	bin/rails restart

start:
	bin/rails server -d

stop:
	kill $$(cat tmp/pids/server.pid) 2>/dev/null || true

dev:
	bin/rails server
