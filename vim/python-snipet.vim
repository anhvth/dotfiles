" Debug
    " vnoremap <leader>d yOprintf(, <esc>pA);<esc>h%a
    vnoremap <leader>p  yOprint(, <esc>pA);<esc>h%a

    inoremap <leader>d <Esc>Oimport ipdb;ipdb.set_trace()<CR><Esc>
    inoremap <leader>c <Esc>0i# <Esc>
    inoremap <leader>C <Esc>:s/# //<CR>
    nnoremap <leader>c <Esc>0i# <Esc>
    nnoremap <leader>C <Esc>:s/# //<CR>

    nnoremap <leader>I :vsplit<CR>:terminal<CR>:set norelativenumber<CR>:set nonumber<CR>iipython<CR>

" python
    "imports
    inoremap iplt import matplotlib.pyplot as plt<CR><esc>i
    inoremap itf import tensorflow as tf<CR><esc>i
    inoremap ipil from PIL import Image <CR><esc>i
    inoremap icv import opencv<CR><esc>i
    inoremap itq from tqdm import tqdm<CR><esc>i
    inoremap igl from glob import glob<CR><esc>i
    "define
    inoremap def<space>show def show(img, dpi=300, size=10):<CR>plt.figure(dpi=dpi, figsize=size),plt.imshow(img); plt.show()<CR>
    "keras
    inoremap kl tf.keras.layers.
    inoremap km tf.keras.models.
