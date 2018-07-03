FROM ruby:2.5.1
MAINTAINER ka <ka.kaosf@gmail.com>
RUN git clone https://github.com/nmt-tokushima/deco-mail-filter /usr/local/deco_mail_filter/s
WORKDIR /usr/local/deco_mail_filter/s
#RUN git checkout v1
RUN bundle install
RUN apt update && apt install -y libdata-uuid-perl
VOLUME /usr/local/deco_mail_filter/s/tmp
ENTRYPOINT ["/usr/local/deco_mail_filter/s/smtpprox_for_decomf"]
