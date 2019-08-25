package com.befovy.fijkplayer;

import java.io.IOException;
import java.io.InputStream;

import tv.danmaku.ijk.media.player.misc.IMediaDataSource;

public class RawMediaDataSource implements IMediaDataSource {
    private InputStream mIs;
    private long mPosition = 0;

    public RawMediaDataSource(InputStream is) {
        mIs = is;
    }

    @Override
    public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {
        if (size <= 0)
            return size;
        if (mPosition != position) {
            mIs.reset();
            mPosition = mIs.skip(position);
        }
        int length = mIs.read(buffer, offset, size);
        mPosition += length;
        return length;
    }

    @Override
    public long getSize() throws IOException {
        return mIs.available();
    }

    @Override
    public void close() throws IOException {
        if (mIs != null)
            mIs.close();
        mIs = null;
    }

}

