FROM python:3.7
#FROM lambci/lambda-base:build

ARG LEPTONICA_VERSION=1.78.0
ARG TESSERACT_VERSION=4.1.0-rc4
ARG AUTOCONF_ARCHIVE_VERSION=2017.09.28
ARG TMP_BUILD=/tmp
ARG TESSERACT=/opt/tesseract
ARG LEPTONICA=/opt/leptonica
ARG DIST=/opt/build-dist

# change TESSERACT_DATA_SUFFIX to use different datafiles (options: "_best", "_fast" and "")
ARG TESSERACT_DATA_SUFFIX=_fast
ARG TESSERACT_DATA_VERSION=4.0.0

#RUN yum makecache fast; yum clean all && yum -y update && yum -y upgrade; yum clean all && \
#    yum install -y yum-plugin-ovl; yum clean all && yum -y groupinstall "Development Tools"; yum clean all

# or clang++ instead of g++ (presumably)
# libjpeg8-dev replaced by libjpeg62-turbo-dev
RUN apt-get update && apt-get install -y --no-install-recommends \
      g++ make \
      libleptonica-dev \
      autoconf automake libtool pkg-config \
      libpng-dev libjpeg62-turbo-dev  \
      libtiff5-dev  zlib1g-dev
#    gcc gcc-c++ make autoconf aclocal automake libtool \
#    libjpeg-devel libpng-devel libtiff-devel zlib-devel \
#    libzip-devel freetype-devel lcms2-devel libwebp-devel \
#    libicu-devel tcl-devel tk-devel pango-devel cairo-devel;

#RUN yum -y install gcc gcc-c++ make autoconf aclocal automake libtool \
#    libjpeg-devel libpng-devel libtiff-devel zlib-devel \
#    libzip-devel freetype-devel lcms2-devel libwebp-devel \
#    libicu-devel tcl-devel tk-devel pango-devel cairo-devel; yum clean all

WORKDIR ${TMP_BUILD}/leptonica-build
RUN curl -L https://github.com/DanBloomberg/leptonica/releases/download/${LEPTONICA_VERSION}/leptonica-${LEPTONICA_VERSION}.tar.gz | tar xz && cd ${TMP_BUILD}/leptonica-build/leptonica-${LEPTONICA_VERSION} && \
    ./configure --prefix=${LEPTONICA} && make && make install && cp -r ./src/.libs /opt/liblept

RUN echo "/opt/leptonica/lib" > /etc/ld.so.conf.d/leptonica.conf && ldconfig

WORKDIR ${TMP_BUILD}/autoconf-build
RUN curl https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-${AUTOCONF_ARCHIVE_VERSION}.tar.xz | tar xJ && \
    cd autoconf-archive-${AUTOCONF_ARCHIVE_VERSION} && ./configure && make && make install && cp ./m4/* /usr/share/aclocal/

WORKDIR ${TMP_BUILD}/tesseract-build
RUN curl -L https://github.com/tesseract-ocr/tesseract/archive/${TESSERACT_VERSION}.tar.gz | tar xz && \
    cd tesseract-${TESSERACT_VERSION} && ./autogen.sh  && PKG_CONFIG_PATH=/opt/leptonica/lib/pkgconfig LIBLEPT_HEADERSDIR=/opt/leptonica/include \
    ./configure --prefix=${TESSERACT} --with-extra-includes=/opt/leptonica/include --with-extra-libraries=/opt/leptonica/lib && make && make install

WORKDIR /opt
RUN mkdir -p ${DIST}/lib && mkdir -p ${DIST}/bin && \
    cp ${TESSERACT}/bin/tesseract ${DIST}/bin/ && \
    cp ${TESSERACT}/lib/libtesseract.so.4  ${DIST}/lib/ && \
    cp ${LEPTONICA}/lib/liblept.so.5 ${DIST}/lib/liblept.so.5 && \
    # cp /usr/lib64/libwebp.so.4 ${DIST}/lib/ && \
    echo -e "LEPTONICA_VERSION=${LEPTONICA_VERSION}\nTESSERACT_VERSION=${TESSERACT_VERSION}\nTESSERACT_DATA_FILES=tessdata${TESSERACT_DATA_SUFFIX}/${TESSERACT_DATA_VERSION}" > ${DIST}/TESSERACT-README.md && \
    find ${DIST}/lib -name '*.so*' | xargs strip -s

WORKDIR ${DIST}/tesseract/share/tessdata
RUN curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/osd.traineddata > osd.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/chi_sim.traineddata > chi_sim.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/chi_sim_vert.traineddata > chi_sim_vert.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/chi_tra.traineddata > chi_tra.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/chi_tra_vert.traineddata > chi_tra_vert.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/eng.traineddata > eng.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/spa.traineddata > spa.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/fra.traineddata > fra.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/deu.traineddata > deu.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/por.traineddata > por.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/rus.traineddata > rus.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/ara.traineddata > ara.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/hin.traineddata > hin.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/jpn.traineddata > jpn.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/jpn_vert.traineddata > jpn_vert.traineddata

ENV TESSDATA_PREFIX ${DIST}/tesseract/share/tessdata

ENV PATH="/opt/build-dist/bin:${PATH}"
WORKDIR /var/task

CMD ["python"]
