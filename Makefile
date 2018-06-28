all: httpd

httpd: httpd.c
	gcc -g -W -Wall  -o httpd httpd.c  -lpthread

clean:
	rm httpd
