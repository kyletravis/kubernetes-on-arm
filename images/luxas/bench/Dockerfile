FROM luxas/raspbian


RUN apt-install build-essential \
				gcc \
				unzip \
				curl && \
	curl -sSL http://www.roylongbottom.org.uk/Raspberry_Pi_Benchmarks.zip > test.zip && \
	unzip test.zip && \
	mv Raspberry* bench

COPY onstart.sh /
COPY main.cpp /perf

CMD ["/onstart.sh"]