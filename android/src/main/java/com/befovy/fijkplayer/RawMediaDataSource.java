package com.befovy.fijkplayer;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.util.Base64;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

import tv.danmaku.ijk.media.player.misc.IMediaDataSource;

public class RawMediaDataSource implements IMediaDataSource {
    private AssetFileDescriptor mDescriptor;
    private BufferedInputStream mStream;
    private RandomAccessFile mRandomAccessFile;
    private long writeSize;

    public RawMediaDataSource(AssetFileDescriptor descriptor, Context context, String asset) {
        this.mDescriptor = descriptor;
        File cacheFile = new File(context.getCacheDir().getAbsolutePath(), Base64.encodeToString(asset.getBytes(), Base64.DEFAULT));

        try {
            mStream = new BufferedInputStream(descriptor.createInputStream());
            mRandomAccessFile = new RandomAccessFile(cacheFile, "rw");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {
        int read = -1;
        // if (mRandomAccessFile.length() == getSize()) {
        //    writeSize = getSize();
        // }
        if (writeSize < position + size) {
            if (mRandomAccessFile.getFilePointer() != writeSize)
                mRandomAccessFile.seek(writeSize);
            int len;
            byte[] rBuf = new byte[1024];
            //while (writeSize < position + size && (len = mStream.read(rBuf)) != -1) {
            while ((len = mStream.read(rBuf)) != -1) {
                writeSize += len;
                mRandomAccessFile.write(rBuf, 0, len);
            }
        }

        if (mRandomAccessFile.getFilePointer() != position)
            mRandomAccessFile.seek(position);

        if (size > 0)
            read = mRandomAccessFile.read(buffer, offset, size);
        return read;

    }

    @Override
    public long getSize() {
        return mDescriptor.getLength();
    }

    @Override
    public void close() throws IOException {
        if (mDescriptor != null)
            mDescriptor.close();
        if (mStream != null)
            mStream.close();
        if (mRandomAccessFile != null)
            mRandomAccessFile.close();
        mStream = null;
        mDescriptor = null;
        mRandomAccessFile = null;
    }

}

