//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

package com.befovy.fijkplayer;


import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

import tv.danmaku.ijk.media.player.misc.IMediaDataSource;

public class FileMediaDataSource implements IMediaDataSource {
    private RandomAccessFile mFile;
    private long mFileSize;

    public FileMediaDataSource(File file) throws IOException {
        mFile = new RandomAccessFile(file, "r");
        mFileSize = mFile.length();
    }

    @Override
    public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {
        if (mFile.getFilePointer() != position)
            mFile.seek(position);

        if (size == 0)
            return 0;

        return mFile.read(buffer, 0, size);
    }

    @Override
    public long getSize() throws IOException {
        return mFileSize;
    }

    @Override
    public void close() throws IOException {
        mFileSize = 0;
        mFile.close();
        mFile = null;
    }
}
